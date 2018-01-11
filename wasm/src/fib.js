// Click event handler
export const registerHandler = (type, fibFun) => {
  const ITER = 50000
  document.getElementsByName(type + '-fib-button')[0].addEventListener('click', (() => {
    const max = document.getElementsByName('fib-max')[0].value
    const t1 = performance.now()
    for (let i = 1; i < ITER; i++) {
      fibFun(max)
    }
    const f = fibFun(max)
    const t2 = performance.now()
    document.getElementsByName(type + '-fib-value')[0].innerText = f
    document.getElementsByName(type + '-fib-time')[0].innerText = ((t2 - t1) / ITER).toFixed(6) + 'ms'
  }))
}

// JS fib impl
export const fib = (n1, n2, i, max) => {
  if (i == max) return n1
  return fib(n2, n1 + n2, i + 1, max)
}

export const fib_to = max => {
  return fib(0, 1, 0, max)
}

// WASM loading
export const loadWasmAndRegister = path => {
  require('webassembly')
    .load(path)
    .then(mod => registerHandler('wasm', mod.exports.fib_to))
}
