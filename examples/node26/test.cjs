const assert = require("node:assert/strict");
const path = require("node:path");

const addon = require(path.join(__dirname, "hello26.node"));

assert.match(process.version, /^v26\./);
assert.equal(addon.hello(), "hello from node 26 example");

console.log("CommonJS Node 26 addon test passed:", process.version);
