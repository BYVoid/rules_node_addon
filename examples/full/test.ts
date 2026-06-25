import assert from "node:assert/strict";
import { copyFileSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

type Addon = {
  hello(): string;
};

type BunRuntime = {
  spawnSync(command: string[], options?: { env?: NodeJS.ProcessEnv }): {
    exitCode: number;
    stdout: Uint8Array;
    stderr: Uint8Array;
  };
};

const bun = (globalThis as { Bun?: BunRuntime }).Bun;
if (bun) {
  const result = bun.spawnSync(
    ["node", "--import", "./node_modules/tsx/dist/loader.mjs", "./test.ts"],
    { env: process.env },
  );
  process.stdout.write(new TextDecoder().decode(result.stdout));
  process.stderr.write(new TextDecoder().decode(result.stderr));
  process.exit(result.exitCode);
}

const require = createRequire(import.meta.url);
const dirname = path.dirname(fileURLToPath(import.meta.url));
const sourceAddonPath = process.env.ADDON_PATH ?? path.join(dirname, "hello_full.node");
const addonPath = path.join(process.env.TEST_TMPDIR ?? dirname, "hello_full.node");
copyFileSync(sourceAddonPath, addonPath);
const addon = require(addonPath) as Addon;

const expected: string = "hello from full TypeScript example";
const actual: string = addon.hello();

assert.equal(
  actual,
  expected,
  `addon.hello() returned "${actual}", expected "${expected}"`,
);

console.log("TypeScript addon test passed:", actual);
