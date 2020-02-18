
const http = require('http');

const hash = {}

const daxy = http.createServer((req, res) => {

  // Cleanup when not responded withing acceptable time
  const timeout = setTimeout(() => {
    delete hash[req.url]
    res.statusCode = 408
    res.end()
  }, process.env.DAMMEN_TURN_TIMEOUT || 300000) // TODO: Make configurable

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

function createSocket(url) {
  var net = require('net');

  var server = net.createServer(function(stream) {
    stream.on('data', function(c) {
      console.log('data:', c.toString());
    });
    stream.on('end', function() {
      server.close();
    });
  });

  // create lis
  server.listen('/tmp/daxy');

  var stream = net.connect('/tmp/daxy');
  stream.write('hello');
  stream.end();
}
