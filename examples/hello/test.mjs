import assert from "node:assert/strict";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const dirname = path.dirname(fileURLToPath(import.meta.url));
const addon = require(path.join(dirname, "hello.node"));

const expected = "hello from rules_node_addon";
const actual = addon.hello();

assert.equal(
  actual,
  expected,
  `addon.hello() returned "${actual}", expected "${expected}"`,
);

console.log("ESM addon test passed:", actual);
