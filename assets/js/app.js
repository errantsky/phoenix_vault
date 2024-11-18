// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

const Hooks = {};

Hooks.KeyboardShortcuts = function (liveSocket) {
  return {
    mounted() {
      // Listener for global keydown events
      this.keydownHandler = (e) => {
        const activeElement = document.activeElement;

        // Ignore key presses if typing in an input or textarea
        if (activeElement.tagName === "INPUT" || activeElement.tagName === "TEXTAREA") {
          return;
        }

        switch (e.key) {
          case "/":
            e.preventDefault(); // Prevent default '/' behavior
            const searchInput = document.getElementById("search-input");
            if (searchInput) {
              searchInput.focus(); // Focus on the search input
            }
            break;

          case "n":
            e.preventDefault(); // Prevent default 'n' behavior
            this.pushEvent("open-new-snapshot-modal", {}); // Push the event to LiveView
            break;

          default:
            return;
        }
      };

      // Attach the event listener
      window.addEventListener("keydown", this.keydownHandler);
    },

    destroyed() {
      // Cleanup listener when the hook is destroyed
      window.removeEventListener("keydown", this.keydownHandler);
    },
  };
};


let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
      KeyboardShortcuts: Hooks.KeyboardShortcuts(liveSocket),
    }
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;