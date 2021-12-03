module.exports = {
	execScript(str) {
		const vm = require('vm');
		const contextObject = {
			require: require,
			console: console,
			process: process,
			global: global,
			URL: URL,
			Buffer: Buffer,
			__filename: "__lit_eval.js"
		}

		return vm.runInNewContext(str, contextObject);
	}
}
