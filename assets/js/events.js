import topbar from "../vendor/topbar"
import { smoothScrollTo } from "./lib/utils"

export function registerTopbar() {
  topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
  window.addEventListener("phx:page-loading-start", info => topbar.delayedShow(250))
  window.addEventListener("phx:page-loading-stop", info => topbar.hide())
}

export function registerGlobalEventHandlers() {
  window.addEventListener("js:scrolltop", e => {
    smoothScrollTo(0, e.target)
  })

  window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  window.addEventListener("js:focus", e => {
    let parent = document.querySelector(e.detail.parent)
    if (parent && isVisible(parent)) {
      e.target.focus()
    }
  })

  window.addEventListener("js:clipcopy", event => {
    if ("clipboard" in navigator) {
      const text = event.target.textContent || event.target.value
      navigator.clipboard.writeText(text)
    } else {
      alert(
        "Sorry, your browser does not support clipboard copy.\nThis generally requires a secure origin — either HTTPS or localhost."
      )
    }
  })
}
