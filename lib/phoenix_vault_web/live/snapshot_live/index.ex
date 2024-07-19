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

    Logger.debug("Index mount socket: #{inspect(socket, pretty: true)}")
    Logger.debug("Index mount session: #{inspect(session, pretty: true)}")

    {:ok, stream(socket, :snapshots, Archive.list_snapshots(socket.assigns[:current_user]))}
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
          payload: %{snapshot_id: snapshot_id, updated_column: updated_column}
        },
        socket
      ) do
    Logger.debug(
      "index handle_info archiver_update fetching snapshot #{snapshot_id} to update #{updated_column}"
    )

    snapshot = Archive.get_snapshot!(snapshot_id, socket.assigns.current_user)

    case Archive.update_snapshot(snapshot, %{updated_column => true}) do
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
end
