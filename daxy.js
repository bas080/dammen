
const http = require('http');

const hash = {}

// Cleanup games that have not been answered and are older then like a long
// time.
const daxy = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/pdn' });

  req.on('data', console.log)

  setTimeout(1000, () => {
    res.statusCode = 408
    res.end()
  })

  req.setTimeout(2000, () => {
    console.log('timed out')
  })

  req.on('timeout', () => {
    console.log('called')
  })

  // Fire and forget
  hash[req.url] &&
    req.pipe(hash[req.url].res)

  hash[req.url] = {req, res}
});

daxy.listen(8080, '127.0.0.1')
