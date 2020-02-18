
const swipl = require('swipl-stdio');
const engine = new swipl.Engine();

engine.call('consult(src/dammen).')
engine.call('consult(src/parse).')

while (true) {
engine.call('field(X).')
  .then(console.log)
}

const http = require('http');

const hash = {}

const daxy = http.createServer((req, res) => {

  // Cleanup when not responded withing acceptable time
  const timeout = setTimeout(() => {
    delete hash[req.url]
    res.statusCode = 408
    res.end()
  }, process.env.DAMMEN_TURN_TIMEOUT || 300000) // TODO: Make configurable

  createSocket(req)

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

// add cb that has errors and such
function createSocket(req, cb) {
  var net = require('net');
  const {spawn} = require('child_process')

  var server = net.createServer(function(stream) {
    stream.on('data', function(c) {
      console.log('data:', c.toString());
    });

    stream.on('end', function() {
      server.close();
    });

    const dammen = spawn('./dammen', [path])

    dammen.on('close', (code) => {
      console.log(`child process exited with code ${code}`);
    });

    dammen.stdout.pipe(process.stdout)
    dammen.stderr.pipe(process.stderr)

  });

  const path = `/tmp${req.url}`

  // create new listener
  server.listen(path);

  var stream = net.connect(path);

  req.pipe(stream)


  // stream.write('hello');
  // stream.end();
}
