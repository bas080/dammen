
const http = require('http');

const hash = {}

// Cleanup games that have not been answered and are older then like a long
// time.
const daxy = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/pdn' });

  req.on('data', console.log)


  // Fire and forget
  hash[req.url] &&
    req.pipe(hash[req.url].res)

  hash[req.url] = {req, res}
});

daxy.setTimeout(1000, a => {
  console.log(a.url)
  a.write(408)
  a.end()
})

daxy.listen(8080, '127.0.0.1')
