import assert from "node:assert/strict";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const dirname = path.dirname(fileURLToPath(import.meta.url));
const addon = require(path.join(dirname, "version.node"));

assert.equal(process.version, "v24.13.0");
assert.equal(addon.getVersion(), "v24.13.0");
assert.equal(addon.getVersion(), process.version);
assert.equal(addon.hello(), "hello from pinned node version example");

console.log("ESM pinned Node version addon test passed:", addon.getVersion());
