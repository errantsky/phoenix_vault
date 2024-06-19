defmodule PhoenixVaultWeb.SnapshotLive.Index do
  use PhoenixVaultWeb, :live_view

  alias PhoenixVault.Archive
  alias PhoenixVault.Snapshot

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :snapshots, Archive.list_snapshots())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Snapshot")
    |> assign(:snapshot, Archive.get_snapshot!(id))
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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    snapshot = Archive.get_snapshot!(id)
    {:ok, _} = Archive.delete_snapshot(snapshot)

    {:noreply, stream_delete(socket, :snapshots, snapshot)}
  end
end
