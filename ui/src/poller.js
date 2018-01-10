const Elm = require('./Poller.elm')

const onBackgroundClicked = () => {
  app.ports.listenBackgroundClick.send(true)
}

// Entry funtion of Elm application, exported via `window` object. (Using webpack feature. See npm-scripts)
// Can be invoked from within HTML template.
const poller = (flags) => {
  const app = Elm.Poller.fullscreen(flags)

  app.ports.setTitle.subscribe((title) => {
    app.ports.receiveTitle.send(document.title = title)
  })
  app.ports.receiveTitle.send(document.title)

  app.ports.setBackgroundClickListener.subscribe((_any_) => {
    document.addEventListener("click", onBackgroundClicked, false)
  })
  app.ports.removeBackgroundClickListener.subscribe((_any_) => {
    document.removeEventListener("click", onBackgroundClicked, false)
  })

  app.ports.addBodyClass.subscribe((classString) => {
    document.body.classList.add(classString)
  })
  app.ports.removeBodyClass.subscribe((classString) => {
    document.body.classList.remove(classString)
  })
}

module.exports = poller
