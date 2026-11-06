/**
 * GGWave data-over-sound service for SyberSpider command transmission.
 * Use case: offline/airgapped command delivery to SyberSpider crawler via acoustic channel.
 *
 * - Encrypts payload with AES-256-GCM (key from GGWAVE_ENCRYPTION_KEY)
 * - CRC32 checksum for integrity
 * - Max payload size: 256 bytes
 * - Protocol prefix: "SPIDER:" for routing
 *
 * @see docs/SYBER_SPYDER_GGWAVE_INTEGRATION.md
 * @see ggerganov/ggwave examples for encoding parameters
 */

const PROTOCOL_PREFIX = "SPIDER:";
const MAX_PAYLOAD_BYTES = 256;
const IV_LENGTH = 12;
const AUTH_TAG_LENGTH = 16;
const KEY_LENGTH = 32;

export interface CommandPayload {
  command: string;
  target: string;
  timestamp: number;
  nonce: string;
}

const PAYLOAD_TTL_MS = 5 * 60 * 1000; // 5 minutes replay window

/**
 * Get encryption key from env (32-byte hex = 64 chars).
 * In production, use Supabase Vault or HIKARU Security Layer.
 */
function getEncryptionKey(): Uint8Array {
  const raw = process.env.GGWAVE_ENCRYPTION_KEY ?? "";
  if (raw.length !== 64 || !/^[0-9a-fA-F]+$/.test(raw)) {
    throw new Error("GGWAVE_ENCRYPTION_KEY must be 32-byte hex (64 chars)");
  }
  const bytes = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    bytes[i] = parseInt(raw.slice(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

/** CRC32 (simple implementation for integrity check). */
function crc32(buffer: Uint8Array): number {
  let crc = 0xffff_ffff;
  for (let i = 0; i < buffer.length; i++) {
    crc ^= buffer[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc >>> 1) ^ (0xedb8_8320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffff_ffff) >>> 0;
}

function serializePayload(payload: CommandPayload): Uint8Array {
  const json = JSON.stringify(payload);
  const encoded = new TextEncoder().encode(json);
  if (encoded.length > MAX_PAYLOAD_BYTES - 4 - IV_LENGTH - AUTH_TAG_LENGTH - PROTOCOL_PREFIX.length) {
    throw new Error(`Payload exceeds max size (${MAX_PAYLOAD_BYTES} bytes)`);
  }
  return encoded;
}

function deserializePayload(bytes: Uint8Array): CommandPayload {
  const json = new TextDecoder().decode(bytes);
  const payload = JSON.parse(json) as CommandPayload;
  if (
    typeof payload.command !== "string" ||
    typeof payload.target !== "string" ||
    typeof payload.timestamp !== "number" ||
    typeof payload.nonce !== "string"
  ) {
    throw new Error("Invalid payload shape");
  }
  return payload;
}

/**
 * GGWaveService: encode commands to acoustic signal and decode with replay protection.
 * Acoustic encode/decode requires ggwave-js (Node) or native bindings; this module
 * handles encryption, CRC32, and protocol prefix. Wire the result to ggwave for audio.
 */
export class GGWaveService {
  private encryptionKey: Uint8Array;

  constructor(encryptionKeyHex?: string) {
    if (encryptionKeyHex) {
      if (encryptionKeyHex.length !== 64 || !/^[0-9a-fA-F]+$/.test(encryptionKeyHex)) {
        throw new Error("encryptionKeyHex must be 32-byte hex (64 chars)");
      }
      this.encryptionKey = new Uint8Array(32);
      for (let i = 0; i < 32; i++) {
        this.encryptionKey[i] = parseInt(encryptionKeyHex.slice(i * 2, i * 2 + 2), 16);
      }
    } else {
      this.encryptionKey = getEncryptionKey();
    }
  }

  /**
   * Encrypt payload (AES-256-GCM), prepend protocol prefix, append CRC32.
   * Returns binary blob to be passed to ggwave-js for encoding to audio.
   */
  async encodeCommand(payload: CommandPayload): Promise<ArrayBuffer> {
    const payloadBytes = serializePayload(payload);
    const iv = crypto.getRandomValues(new Uint8Array(IV_LENGTH));

    const key = await crypto.subtle.importKey(
      "raw",
      this.encryptionKey,
      { name: "AES-GCM", length: 256 },
      false,
      ["encrypt"]
    );

    const ciphertext = await crypto.subtle.encrypt(
      { name: "AES-GCM", iv, tagLength: AUTH_TAG_LENGTH * 8 },
      key,
      payloadBytes
    );

    const prefix = new TextEncoder().encode(PROTOCOL_PREFIX);
    const crcBuf = new ArrayBuffer(4);
    const full = new Uint8Array(prefix.length + iv.length + ciphertext.byteLength + 4);
    full.set(prefix, 0);
    full.set(iv, prefix.length);
    full.set(new Uint8Array(ciphertext), prefix.length + iv.length);

    const crc = crc32(new Uint8Array(ciphertext));
    new DataView(crcBuf).setUint32(0, crc, false);
    full.set(new Uint8Array(crcBuf), full.length - 4);

    return full.buffer;
  }

  /**
   * Decode binary blob (from ggwave-js decode): verify prefix, CRC32, decrypt, validate timestamp.
   */
  async decodeAudio(buffer: ArrayBuffer): Promise<CommandPayload> {
    const bytes = new Uint8Array(buffer);
    const prefixBytes = new TextEncoder().encode(PROTOCOL_PREFIX);
    if (bytes.length < prefixBytes.length + IV_LENGTH + AUTH_TAG_LENGTH + 4) {
      throw new Error("Payload too short");
    }

    for (let i = 0; i < prefixBytes.length; i++) {
      if (bytes[i] !== prefixBytes[i]) throw new Error("Invalid protocol prefix");
    }

    const iv = bytes.slice(prefixBytes.length, prefixBytes.length + IV_LENGTH);
    const ciphertext = bytes.slice(prefixBytes.length + IV_LENGTH, bytes.length - 4);
    const storedCrc = new DataView(buffer).getUint32(bytes.length - 4, false);
    const computedCrc = crc32(ciphertext);
    if (storedCrc !== computedCrc) throw new Error("CRC32 integrity check failed");

    const key = await crypto.subtle.importKey(
      "raw",
      this.encryptionKey,
      { name: "AES-GCM", length: 256 },
      false,
      ["decrypt"]
    );

    const plaintext = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv, tagLength: AUTH_TAG_LENGTH * 8 },
      key,
      ciphertext
    );

    const payload = deserializePayload(new Uint8Array(plaintext));

    const now = Date.now();
    if (Math.abs(now - payload.timestamp) > PAYLOAD_TTL_MS) {
      throw new Error("Expired: timestamp outside replay window");
    }

    return payload;
  }
}
