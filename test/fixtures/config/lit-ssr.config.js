import build from "../../../src/build.mjs"
import { plugins } from "./esbuild-plugins.js"

const esbuildOptions = { plugins }

build(esbuildOptions)