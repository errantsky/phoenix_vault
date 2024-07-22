defmodule PhoenixVaultWeb.SnapshotLive.Index do
  require Logger
  use PhoenixVaultWeb, :live_view

  alias PhoenixVault.Archive
  alias PhoenixVault.Schemas.Snapshot

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Logger.info("Socket connected, subscribing to snapshots")
      Phoenix.PubSub.subscribe(PhoenixVault.PubSub, "snapshots")
    end

    search_query = nil
    snapshots = Archive.list_snapshots(socket.assigns[:current_user], search_query)

    {:ok,
     socket
     |> assign(:search_query, search_query)
     |> stream(:snapshots, snapshots)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Snapshot")
    |> assign(:snapshot, Archive.get_snapshot!(id, socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Snapshot")
    |> assign(:snapshot, %Snapshot{tags: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Snapshots")
    |> assign(:snapshot, nil)
  end

  @impl true
  def handle_info({PhoenixVaultWeb.SnapshotLive.FormComponent, {:saved, snapshot}}, socket) do
    {:noreply, stream_insert(socket, :snapshots, snapshot)}
  end

  def handle_info(
        {PhoenixVaultWeb.SnapshotLive.BulkSnapshotComponent, {:saved, snapshots}},
        socket
      ) do
    {:noreply, stream(socket, :snapshots, snapshots)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "snapshots",
          event: "archiver_update",
          payload: %{snapshot_id: snapshot_id, updated_columns: updated_columns}
        },
        socket
      ) do
    Logger.debug(
      "index handle_info archiver_update fetching snapshot #{snapshot_id} to update #{inspect(updated_columns)}"
    )

    snapshot = Archive.get_snapshot!(snapshot_id, socket.assigns.current_user)

    case Archive.update_snapshot(snapshot, updated_columns) do
      {:ok, updated_snapshot} ->
        Logger.debug(
          "index handle_info archiver_update updated_snapshot: #{inspect(updated_snapshot, pretty: true)}"
        )

        {:noreply, stream_insert(socket, :snapshots, updated_snapshot)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error(
          "Index handle_info archiver_update: Failed to update the snapshot #{snapshot.id}: #{inspect(changeset)}"
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    snapshot = Archive.get_snapshot!(id, socket.assigns.current_user)
    {:ok, _} = Archive.delete_snapshot(snapshot)

    {:noreply, stream_delete(socket, :snapshots, snapshot)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    snapshots = Archive.list_snapshots(socket.assigns[:current_user], query)
    Logger.debug("handle_event search: Fetched #{snapshots |> length()} queries.")
    {:noreply, assign(socket, :search_query, query) |> stream(:snapshots, snapshots, reset: true)}
  end
  
  @impl true
  def handle_event("change_query", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def handle_event("reset_search", _params, socket) do
    snapshots = Archive.list_snapshots(socket.assigns[:current_user], nil)
    Logger.debug("index handle_event reset search in progress.")
    {:noreply, assign(socket, :search_query, nil) |> stream(:snapshots, snapshots, reset: true)}
  end
end
