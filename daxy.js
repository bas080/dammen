const toString = require('stream-to-string')
const swipl = require('swipl-stdio');
const {serialize, variable, compound, list} = swipl.term
const engine = new swipl.Engine();

engine.call('consult(src/dammen).')
engine.call('consult(src/pdn).')

const http = require('http');

const hash = {}

const daxy = http.createServer((req, res) => {

  // Cleanup when not responded withing acceptable time
  const timeout = setTimeout(() => {
    delete hash[req.url]
    res.statusCode = 408
    res.end()
  }, process.env.DAMMEN_TURN_TIMEOUT || 300000) // TODO: Make configurable

  toString(req)
    .then(pdn => {
      engine.call(
        serialize(
          compound('parse_pdn_string', [
            variable("Objects"),
            pdn
          ])
        ))
    })
    .then(JSON.stringify)
    .then(console.log.bind(console, req.url))
  .catch(console.error)

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
