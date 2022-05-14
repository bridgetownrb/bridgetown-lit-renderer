const http = require("http")
const litexec = require("./server/ssr_exec")

const server = http.createServer((req, res) => {
  if (req.method === "POST" && req.headers.authorization?.endsWith(process.env.LIT_SSR_AUTH_TOKEN)) {
    let body = ""
    req.on("data", (chunk) => {
      body += chunk.toString()
    });
    req.on("end", () => {
      let ret = "";
      try {
        ret = litexec.execScript(body)
      } catch (e) {
        console.warn(e);
      }
      if (ret) {
				res.end(ret.toString())
			} else {
				res.end("SCRIPT NOT VALID!")
			}
    })
  } else {
    res.statusCode = 400
    res.end("Invalid Request!")
  }
})

const port = process.env.LIT_SSR_SERVER_PORT
server.listen(port, "127.0.0.1")
