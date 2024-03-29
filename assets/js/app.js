import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { registerGlobalEventHandlers, registerTopbar } from "./events";
import hooks from "./hooks";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: {
    _csrf_token: csrfToken,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  },
  hooks: hooks,
});

// Show progress bar on live navigation and form submits
registerTopbar();

// Handle custom events dispatched with JS.dispatch/3
registerGlobalEventHandlers();

// connect if there are any LiveViews on the page
liveSocket.connect();

// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug()
window.liveSocket = liveSocket;
