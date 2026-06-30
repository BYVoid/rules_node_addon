import assert from "node:assert/strict";
import { copyFileSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

type Addon = {
  add(left: number, right: number): number;
  getAsyncReport(label: string, value: number): Promise<{
    label: string;
    input: number;
    doubled: number;
    source: string;
  }>;
  hello(): string;
  makeMetadata(): {
    name: string;
    count: number;
    enabled: boolean;
    tags: number[];
    nested: {
      runtime: string;
      values: number[];
    };
    bytes: Uint8Array;
    nothing: null;
  };
  multiplyWithWorker(
    left: number,
    right: number,
    callback: (error: Error | null, value?: number) => void,
  ): void;
  sumArray(values: number[]): number;
};

const require = createRequire(import.meta.url);
const dirname = path.dirname(fileURLToPath(import.meta.url));
const configuredAddonPath = process.env.ADDON_PATH;
const sourceAddonPath = configuredAddonPath
  ? path.resolve(dirname, configuredAddonPath)
  : path.join(dirname, "hello_full.node");
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

assert.equal(addon.add(20, 22), 42);
assert.equal(addon.sumArray([1, 2, 3, 4]), 10);

const metadata = addon.makeMetadata();
assert.deepEqual(
  {
    name: metadata.name,
    count: metadata.count,
    enabled: metadata.enabled,
    tags: metadata.tags,
    nested: metadata.nested,
    bytes: Array.from(metadata.bytes),
    nothing: metadata.nothing,
  },
  {
    name: "full-example",
    count: 3,
    enabled: true,
    tags: [24, 14, 0],
    nested: {
      runtime: "node-addon-api",
      values: [1, 2, 3],
    },
    bytes: [0x6e, 0x61, 0x70, 0x69],
    nothing: null,
  },
);

const workerResult = await new Promise<number>((resolve, reject) => {
  addon.multiplyWithWorker(6, 7, (error, value) => {
    if (error) {
      reject(error);
      return;
    }
    resolve(value as number);
  });
});
assert.equal(workerResult, 42);

const report = await addon.getAsyncReport("typed", 21);
assert.deepEqual(report, {
  label: "typed",
  input: 21,
  doubled: 42,
  source: "promise-worker",
});

console.log("TypeScript addon test passed:", actual, workerResult, report.doubled);
