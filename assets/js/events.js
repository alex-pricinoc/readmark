import topbar from "../vendor/topbar";

export function registerTopbar() {
  topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
  let topBarScheduled;

  window.addEventListener("phx:page-loading-start", () => {
    if (!topBarScheduled) {
      topBarScheduled = setTimeout(() => topbar.show(), 200);
    }
  });

  window.addEventListener("phx:page-loading-stop", () => {
    clearTimeout(topBarScheduled);
    topBarScheduled = false;
    topbar.hide();
  });
}

export function registerGlobalEventHandlers() {
  window.addEventListener("js:exec", (e) => e.target[e.detail.call](...e.detail.args));
  window.addEventListener("js:focus", (e) => {
    let parent = document.querySelector(e.detail.parent);
    if (parent && isVisible(parent)) {
      e.target.focus();
    }
  });
}
