/**
 * Unit tests for GGWaveService: encode/decode, CRC32, replay protection.
 * Run: npm test or deno test GGWaveService.test.ts
 */

import { assertEquals, assertRejects } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { GGWaveService } from "../lib/GGWaveService.ts";

const TEST_KEY = "0".repeat(64).replace(/0/g, (_, i) => (i % 16).toString(16)).slice(0, 64);
if (TEST_KEY.length !== 64) throw new Error("Test key must be 64 hex chars");

Deno.test("GGWaveService encodes and decodes command payload", async () => {
  const service = new GGWaveService(TEST_KEY);
  const payload = {
    command: "scan",
    target: "192.168.1.1",
    timestamp: Date.now(),
    nonce: crypto.randomUUID(),
  };
  const encoded = await service.encodeCommand(payload);
  const decoded = await service.decodeAudio(encoded);
  assertEquals(decoded.command, payload.command);
  assertEquals(decoded.target, payload.target);
  assertEquals(decoded.timestamp, payload.timestamp);
  assertEquals(decoded.nonce, payload.nonce);
});

Deno.test("GGWaveService rejects replayed commands (timestamp validation)", async () => {
  const service = new GGWaveService(TEST_KEY);
  const oldPayload = {
    command: "scan",
    target: "x",
    timestamp: Date.now() - 600_000,
    nonce: crypto.randomUUID(),
  };
  const encoded = await service.encodeCommand(oldPayload);
  await assertRejects(
    () => service.decodeAudio(encoded),
    Error,
    "Expired"
  );
});

Deno.test("GGWaveService rejects invalid protocol prefix", async () => {
  const service = new GGWaveService(TEST_KEY);
  const badBuffer = new ArrayBuffer(64);
  await assertRejects(
    () => service.decodeAudio(badBuffer),
    Error,
    "Invalid protocol prefix"
  );
});
