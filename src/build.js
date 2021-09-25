const path = require("path")

module.exports = (esbuildOptions) => {
  let inputData = [];

  process.stdin.resume();
  process.stdin.setEncoding('utf8');

  process.stdin.on('data', data => {
    inputData.push(data)
  })

  process.stdin.on('end', () => {
    const inputValues = JSON.parse(inputData.join())

    require('esbuild').build({
      ...esbuildOptions,
      stdin: {
        contents: inputValues.code,
        resolveDir: process.cwd(),
        sourcefile: 'lit-ssr-output.js' // imaginary file
      },
      platform: "node",
      inject: [path.join(__dirname, "import-meta-url-shim.js")],
      define: { "import.meta.url": "import_meta_url" },
      bundle: true,
      write: false,
    }).then(result => {
      process.stdout.write(result.outputFiles[0].text)
    }).catch(_e => { })
  })
}
