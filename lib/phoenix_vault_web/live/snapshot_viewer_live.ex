defmodule PhoenixVaultWeb.SnapshotViewerLive do
  require Logger
  alias PhoenixVault.Archivers.ArchiverConfig
  alias PhoenixVault.Archive
  use PhoenixVaultWeb, :live_view

  @valid_sources MapSet.new(~w(pdf screenshot html))

  @impl true
  def mount(%{"id" => snapshot_id} = params, _session, socket) do
    # todo sustain selected_source on refresh

    selected_source =
      case Map.get(params, "selected_source") do
        "pdf" -> "pdf"
        "screenshot" -> "screenshot"
        "single-file" -> "single-file"
        _ -> "single-file"
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
        :single_file_path,
        static_path(
          socket,
          Path.join([
            "/archive",
            to_string(snapshot.id),
            ArchiverConfig.get_root_domain(snapshot.url),
            "#{snapshot.id}.html"
          ])
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
        "single-file" -> "single-file"
        # default to "single-file" if the value is not valid
        _ -> "single-file"
      end

    # todo error handling
    snapshot = Archive.get_snapshot!(snapshot_id, socket.assigns.current_user)

    # todo refactor path finder
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
        :single_file_path,
        static_path(
          socket,
          Path.join([
            "/archive",
            to_string(snapshot.id),
            "#{snapshot.id}.html"
          ])
        )
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("next", _unsigned_params, socket) do


    with next_snapshot when not is_nil(next_snapshot) <-
           Archive.get_next_snapshot(socket.assigns.current_snapshot) do
      query_params =
        if MapSet.member?(@valid_sources, socket.assigns.selected_source) do
          "?selected_source=#{socket.assigns.selected_source}"
        else
          ""
        end

      path = ~p"/snapshots/view/#{next_snapshot.id}" <> query_params

      {:noreply, push_patch(socket, to: path, replace: true)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev", _unsigned_params, socket) do


    with prev_snapshot when not is_nil(prev_snapshot) <-
           Archive.get_prev_snapshot(socket.assigns.current_snapshot) do
      query_params =
        if MapSet.member?(@valid_sources, socket.assigns.selected_source) do
          "?selected_source=#{socket.assigns.selected_source}"
        else
          ""
        end

      path = ~p"/snapshots/view/#{prev_snapshot.id}" <> query_params

      {:noreply, push_patch(socket, to: path, replace: true)}
    else
      _ -> {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("navigate-snapshot", %{"key" => key} = params, socket) do
    case key do
      "ArrowRight" -> handle_event("next", params, socket)
      "ArrowLeft" -> handle_event("prev", params, socket)
      _ -> {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("navigate-snapshot", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("screenshot", _unsigned_params, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/snapshots/view/#{socket.assigns.current_snapshot.id}?selected_source=screenshot"
     )}
  end

  @impl true
  def handle_event("pdf", _unsigned_params, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/snapshots/view/#{socket.assigns.current_snapshot.id}?selected_source=pdf"
     )}
  end

  @impl true
  def handle_event("single-file", _unsigned_params, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/snapshots/view/#{socket.assigns.current_snapshot.id}?selected_source=html"
     )}
  end
end
