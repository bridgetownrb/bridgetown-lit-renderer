const colors = require("colors/safe")

const originalConsoleLog = console.log

console.log = function () {
  args = []
  args.push(colors.rainbow("[LitSSR]"))
  // Note: arguments is part of the prototype
  for (let i = 0; i < arguments.length; i++) {
    args.push(arguments[i])
  }
  originalConsoleLog.apply(console, args)
}

module.exports = {
  execScript(str) {
    const vm = require("vm")
    const contextObject = {
      require: require,
      console: console,
      process: process,
      global: global,
      URL: URL,
      Buffer: Buffer,
      __filename: "__lit_eval.js",
    }

    return vm.runInNewContext(str, contextObject)
  },
}
