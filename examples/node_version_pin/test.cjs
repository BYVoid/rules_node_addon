const assert = require("node:assert/strict");
const path = require("node:path");

const addon = require(path.join(__dirname, "version.node"));

assert.equal(process.version, "v24.13.0");
assert.equal(addon.getVersion(), "v24.13.0");
assert.equal(addon.getVersion(), process.version);
assert.equal(addon.hello(), "hello from pinned node version example");

console.log("CommonJS pinned Node version addon test passed:", addon.getVersion());
