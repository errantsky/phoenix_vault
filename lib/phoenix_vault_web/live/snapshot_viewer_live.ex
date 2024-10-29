defmodule PhoenixVaultWeb.SnapshotViewerLive do
  require Logger
  alias PhoenixVault.Archivers.ArchiverConfig
  alias PhoenixVault.Archive
  use PhoenixVaultWeb, :live_view

  @impl true
  def mount(%{"id" => snapshot_id} = params, _session, socket) do
    # todo sustain selected_source on refresh

    selected_source =
      case Map.get(params, "selected_source") do
        "pdf" -> "pdf"
        "screenshot" -> "screenshot"
        "html" -> "html"
        _ -> "html" # default to "html" if the value is not valid
      end

    Logger.debug("SnapshotViewer mount socket_assigns: #{inspect(socket.assigns, pretty: true)}")

    # todo error handling
    snapshot = Archive.get_snapshot!(snapshot_id, socket.assigns.current_user)

    socket =
      socket
      |> assign(:current_snapshot, snapshot)
      |> assign(:selected_source, selected_source)
      |> assign(
        :pdf_path,
        static_path(
          socket,
          Path.join(["/archive", to_string(snapshot.id), "#{snapshot.id}.pdf"])
        )
      )
      |> assign(
        :screenshot_path,
        static_path(
          socket,
          Path.join(["/archive", to_string(snapshot.id), "#{snapshot.id}.png"])
        )
      )
      |> assign(
        :html_path,
        static_path(
          socket,
          Path.join(["/archive", to_string(snapshot.id), ArchiverConfig.get_root_domain(snapshot.url), "index.html"])
        )
      )

    {:ok, socket}
  end

  @impl true
    def handle_params(%{"id" => snapshot_id} = params, _uri, socket) do
      selected_source =
        case Map.get(params, "selected_source") do
          "pdf" -> "pdf"
          "screenshot" -> "screenshot"
          "html" -> "html"
          _ -> "html" # default to "html" if the value is not valid
        end

      # todo error handling
      snapshot = Archive.get_snapshot!(snapshot_id, socket.assigns.current_user)

      socket =
        socket
        |> assign(:current_snapshot, snapshot)
        |> assign(:selected_source, selected_source)
        |> assign(
          :pdf_path,
          static_path(
            socket,
            Path.join(["/archive", to_string(snapshot.id), "#{snapshot.id}.pdf"])
          )
        )
        |> assign(
          :screenshot_path,
          static_path(
            socket,
            Path.join(["/archive", to_string(snapshot.id), "#{snapshot.id}.png"])
          )
        )
        |> assign(
          :html_path,
          static_path(
            socket,
            Path.join(["/archive", to_string(snapshot.id), ArchiverConfig.get_root_domain(snapshot.url), "index.html"])
          )
        )

      {:noreply, socket}
    end

  @impl true
  def handle_event("next", _unsigned_params, socket) do
    Logger.debug(
      "Fetching next snapshot after snapshot id: #{socket.assigns.current_snapshot.id}"
    )

    case Archive.get_next_snapshot(socket.assigns.current_snapshot) do
      nil ->
        {:noreply, socket}

      next_snapshot ->
        {:noreply, push_patch(socket, to: "/snapshots/view/#{next_snapshot.id}", replace: true)}
    end
  end

  @impl true
  def handle_event("prev", _unsigned_params, socket) do
    Logger.debug(
      "Fetching prev snapshot after snapshot id: #{socket.assigns.current_snapshot.id}"
    )
    
    case Archive.get_prev_snapshot(socket.assigns.current_snapshot) do
      nil ->
        {:noreply, socket}

      prev_snapshot ->
        {:noreply, push_patch(socket, to: "/snapshots/view/#{prev_snapshot.id}", replace: true)}
    end
  end

  @impl true
  def handle_event("screenshot", _unsigned_params, socket) do
    socket = socket
    |> assign(:selected_source, "screenshot")

    {:noreply, socket}
  end

  @impl true
  def handle_event("pdf", _unsigned_params, socket) do
    socket = socket
    |> assign(:selected_source, "pdf")

    {:noreply, socket}
  end

  @impl true
  def handle_event("html", _unsigned_params, socket) do
    socket = socket
    |> assign(:selected_source, "html")

    {:noreply, socket}
  end
end
