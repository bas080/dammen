// author:  Bas Huis
// github:  https://github.com/bas080/dammen
// created: Mon Mar  2 20:02:00 CET 2020
// license: GNU General Public License 3.0

const toString = require('stream-to-string')

createDaxy({
  hash: {},
  swipl: require('swipl-stdio'),
  logger: undefined, // TODO: Implement logging.
  http: require('http'),
})
  .listen(8080, '127.0.0.1')

function createDaxy({hash, swipl, http, logger}) {
  const {serialize, variable, compound, list} = swipl.term

  const engine = new swipl.Engine();

  Promise.all([
    engine.call('consult(src/dammen).'),
    engine.call('consult(src/pdn).'),
    engine.call('consult(src/cli).')
  ]).catch(reason => {
    process.stderr.write(reason)
    process.exit(1)
  })

  return http.createServer((req, res) => {
    // Cleanup when not responded within acceptable time.
    // Required for memory reasons.
    const timeout = setTimeout(() => {
      delete hash[req.url]
      res.statusCode = 408
      res.end()
    }, process.env.DAMMEN_TURN_TIMEOUT || 300000)

    // Check if the file is a valid pdn file with valid moves
    // TODO: just testing if the binding is working well and it is.
    // should instead call function for checking pdn and all moves.
    toString(req)
      .then(pdn =>
        swipl.call(
          serialize(
            compound('pdn_objects', [
              pdn,
              variable("Objects")
            ])
          )))
        .then(result => {
          console.log(JSON.stringify(result, null, 2))
        })

    // TODO: check if the req will be cleaned up.
    res.on('close', () => {
      clearTimeout(timeout)
    })

    // Pipe the request body of the current player directly to the other player.
    hash[req.url] && (
      res.writeHead(200, { 'Content-Type': 'text/pdn' }),
      req.pipe(hash[req.url].res))

    hash[req.url] = {req, res}
  })
}

