const path = require("path")
const glob = require("glob")

// Glob plugin derived from:
// https://github.com/thomaschaaf/esbuild-plugin-import-glob
// https://github.com/xiaohui-zhangxh/jsbundling-rails/commit/b15025dcc20f664b2b0eb238915991afdbc7cb58
const importGlobPlugin = () => ({
  name: "import-glob",
  setup: (build) => {
    build.onResolve({ filter: /\*/ }, async (args) => {
      if (args.resolveDir === "") {
        return; // Ignore unresolvable paths
      }

      const adjustedPath = args.path.replace(/^bridgetownComponents\//, "../src/_components/")

      return {
        path: adjustedPath,
        namespace: "import-glob",
        pluginData: {
          path: adjustedPath,
          resolveDir: args.resolveDir,
        },
      }
    })

    build.onLoad({ filter: /.*/, namespace: "import-glob" }, async (args) => {
      const files = glob.sync(args.pluginData.path, {
        cwd: args.pluginData.resolveDir,
      }).sort()

      const importerCode = `
        ${files
          .map((module, index) => `import * as module${index} from '${module}'`)
          .join(';')}
        const modules = {${files
          .map((module, index) => `
            "${module.replace("../src/_components/", "")}": module${index},`)
          .join("")}
        };
        export default modules;
      `

      return { contents: importerCode, resolveDir: args.pluginData.resolveDir }
    })
  },
})

module.exports = (esbuildOptions) => {
  let inputData = [];

  process.stdin.resume();
  process.stdin.setEncoding('utf8');

  process.stdin.on('data', data => {
    inputData.push(data)
  })

  process.stdin.on('end', () => {
    const inputValues = JSON.parse(inputData.join())

    esbuildOptions.plugins = esbuildOptions.plugins || []
    esbuildOptions.plugins.unshift(importGlobPlugin())

    require('esbuild').build({
      ...esbuildOptions,
      stdin: {
        contents: inputValues.code,
        resolveDir: process.cwd(),
        sourcefile: 'lit-ssr-output.js' // imaginary file
      },
      platform: "node",
      inject: [path.join(__dirname, "server", "import-meta-url-shim.js")],
      define: { "import.meta.url": "import_meta_url" },
      bundle: true,
      write: false,
    }).then(result => {
      process.stdout.write(result.outputFiles[0].text)
    }).catch(_e => { })
  })
}
