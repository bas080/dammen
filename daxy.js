
const http = require('http');

const hash = {}

const daxy = http.createServer((req, res) => {
  const timeout = setTimeout(() => {
    delete hash[req.url]
    res.statusCode = 408
    res.end()
    console.log('timedout')
  }, 1000)

  res.on('close', () => {
    clearTimeout(timeout)
  })

  res.writeHead(200, { 'Content-Type': 'text/pdn' });

  // Fire and forget
  hash[req.url] &&
    req.pipe(hash[req.url].res)

  hash[req.url] = {req, res}
});

daxy.listen(8080, '127.0.0.1')
