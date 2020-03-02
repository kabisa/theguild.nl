//= require ./_console-jobs
//= require ./delLocalStorage

if (navigator.serviceWorker) {
  navigator.serviceWorker
    .register("/javascripts/serviceworker.js", { scope: "./" })
    .then(function() {
      console.log("[Companion]", "Service worker registered!")
    })
    .catch(function(error) {
      // registration failed :(
      console.log("[Companion]", "Service worker registration failed: " + error)
    })
}
