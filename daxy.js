const toString = require('stream-to-string')
const swipl = require('swipl-stdio');
const {serialize, variable, compound, list} = swipl.term
const engine = new swipl.Engine();

engine.call('consult(src/dammen).')
engine.call('consult(src/pdn).')

const http = require('http');

const hash = {}

const daxy = http.createServer((req, res) => {

  // Cleanup when not responded within acceptable time
  // Required for memory reasons
  // Consider abstracting into auto cleanup hashmap tool
  const timeout = setTimeout(() => {
    delete hash[req.url]
    res.statusCode = 408
    res.end()
  }, process.env.DAMMEN_TURN_TIMEOUT || 300000)

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

  res.writeHead(200, { 'Content-Type': 'text/pdn' });

  // Fire and forget
  hash[req.url] &&
    req.pipe(hash[req.url].res)

  hash[req.url] = {req, res}
});

daxy.listen(8080, '127.0.0.1')

// deletes property after n seconds
function DebounceMap() {
  let map;
  let after;

  this.constructor = (init, milliseconds = 1000) => {
    map = init || {}
    after = milliseconds || after
  }

  this.get= (prop) => {
    return map[prop] && map[prop].value
  }

  this.set = (prop, value, millisecondsOveride) => {
    map[prop] && clearTimeout(map[prop].timeout)

    const timeout = setTimeout(() => {
      delete map[prop]
    }, milliseconds || milliseconds)

    map[prop] = {
      value
      timeout
    }

  }
}
