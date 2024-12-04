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

// Custom functions
// In your app.js file or a custom hook file
let Hooks = {};

Hooks.PdfViewer = {
  mounted() {
    this.initializePdfViewer(this.el.dataset.pdfPath);
  },
  updated() {
    if (this.el.style.display !== "none") {
      this.initializePdfViewer(this.el.dataset.pdfPath);
    }
  },
  initializePdfViewer(url) {
    import(
      "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.6.82/pdf.min.mjs"
    ).then((pdfjsLib) => {
      pdfjsLib.GlobalWorkerOptions.workerSrc =
        "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.6.82/pdf.worker.min.mjs";

      let pdfDoc = null;
      let pageNum = 1;
      const scale = 1.5;
      const canvas = document.getElementById("pdf-canvas");
      const ctx = canvas.getContext("2d");
      let renderTask = null; // To track the current render task

      const renderPage = async (num) => {
        // Cancel the previous render task if it exists
        if (renderTask) {
          renderTask.cancel();
        }

        const page = await pdfDoc.getPage(num);
        const viewport = page.getViewport({ scale });
        canvas.height = viewport.height;
        canvas.width = viewport.width;

        const renderContext = {
          canvasContext: ctx,
          viewport: viewport,
        };

        // Start the render task
        renderTask = page.render(renderContext);

        try {
          // Wait for rendering to complete
          await renderTask.promise;

          // Update page counters after successful render
          document.getElementById("page_num").textContent = num;
        } catch (error) {
          if (error.name === "RenderingCancelledException") {
            console.log("Rendering canceled:", error.message);
          } else {
            console.error("Error during rendering:", error);
          }
        }
      };

      // Load the PDF document
      pdfjsLib.getDocument(url).promise.then((pdf) => {
        pdfDoc = pdf;
        document.getElementById("page_count").textContent = pdfDoc.numPages;
        renderPage(pageNum); // Render the first page
      });

      // Set up navigation
      document.getElementById("prev").addEventListener("click", () => {
        if (pageNum <= 1) return;
        pageNum--;
        renderPage(pageNum);
      });

      document.getElementById("next").addEventListener("click", () => {
        if (pageNum >= pdfDoc.numPages) return;
        pageNum++;
        renderPage(pageNum);
      });
    });
  },
};

Hooks.FocusSearch = {
  mounted() {
    this.handleEvent("focus_search_input", () => {
      document.getElementById("search-input").focus();
    });

    window.addEventListener("keydown", (event) => {
      const activeElement = document.activeElement;

      if (
        activeElement.tagName === "INPUT" ||
        activeElement.tagName == "TEXTAREA" ||
        activeElement.isContentEditable
      ) {
        return;
      }

      if (["/", "n"].includes(event.key)) {
        this.pushEvent("keyboard-shortcut", { key: event.key });
      }
    });
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
