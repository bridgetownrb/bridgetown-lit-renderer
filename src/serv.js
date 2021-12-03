const http = require("http")
const litexec = require("./litexec")

const server = http.createServer((req, res) => {
  if (req.method === "POST") {
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
    res.end("Invalid Request!")
  }
})

const port = process.env.LIT_SSR_SERVER_PORT || 5500
server.listen(port);
