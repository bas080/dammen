const toString = require('stream-to-string')
const swipl = require('swipl-stdio');
const {serialize, variable, compound, list} = swipl.term
const engine = new swipl.Engine();

engine.call('consult(src/dammen).')
engine.call('consult(src/pdn).')

const http = require('http');

const hash = {}

const daxy = http.createServer((req, res) => {

  // Cleanup when not responded within acceptable time.
  // Required for memory reasons.
  const timeout = setTimeout(() => {
    delete hash[req.url]
    res.statusCode = 408
    res.end()
  }, process.env.DAMMEN_TURN_TIMEOUT || 300000)

  // Check if the file is a valid pdn file with valid moves
  toString(req)
    .then(pdn =>
      engine.call(
        serialize(
          // just testing if the binding is working well and it is.
          // should instead call function for checking pdn and all moves.
          compound('parse_pdn_string', [
            variable("Objects"),
            pdn
          ])
        )))
      .then(result => {
        console.log(JSON.stringify(result))
      })

  res.on('close', () => {
    clearTimeout(timeout)
  })

  // Pipe the request body of the current player directly to the other player.
  hash[req.url] && (
    res.writeHead(200, { 'Content-Type': 'text/pdn' });
    req.pipe(hash[req.url].res))

  hash[req.url] = {req, res}
});

daxy.listen(8080, '127.0.0.1')
