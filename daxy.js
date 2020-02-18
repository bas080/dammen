
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

console.log(daxy instanceof http.Server)

daxy.setTimeout(1000, console.error)

daxy.listen(8080, '127.0.0.1')
