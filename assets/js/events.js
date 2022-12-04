import topbar from "../vendor/topbar"

export function registerTopbar() {
  topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
  window.addEventListener("phx:page-loading-start", (info) => topbar.delayedShow(200))
  window.addEventListener("phx:page-loading-stop", (info) => topbar.hide())
}

export function registerGlobalEventHandlers() {
  window.addEventListener("js:exec", (e) => e.target[e.detail.call](...e.detail.args))
  window.addEventListener("js:focus", (e) => {
    let parent = document.querySelector(e.detail.parent)
    if (parent && isVisible(parent)) {
      e.target.focus()
    }
  })

  window.addEventListener("js:tab-selected", ({ detail }) => {
    let select = document.getElementById(detail.id)
    let link = document.getElementById(select.value)
    liveSocket.execJS(link, link.getAttribute("phx-click"))
  })
}
