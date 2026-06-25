import assert from "node:assert/strict";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const dirname = path.dirname(fileURLToPath(import.meta.url));
const addon = require(path.join(dirname, "hello26.node"));

assert.match(process.version, /^v26\./);
assert.equal(addon.hello(), "hello from node 26 example");

console.log("ESM Node 26 addon test passed:", process.version);
