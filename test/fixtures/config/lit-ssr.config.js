const build = require("../../../src/build")
const { plugins } = require("./esbuild-plugins.js")

const esbuildOptions = { plugins }

build(esbuildOptions)