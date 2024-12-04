defmodule PhoenixVaultWeb.SnapshotLive.Index do
  require Logger
  use PhoenixVaultWeb, :live_view

  alias PhoenixVault.Archive
  alias PhoenixVault.Schemas.Snapshot

  @per_page Archive.snapshot_table_per_page()
  @overfetch_factor Archive.snapshot_table_overfetch_factor()

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PhoenixVault.PubSub, "snapshots")
    end

    {
      :ok,
      socket
      |> assign(:search_query, nil)
      |> assign(page: 1)
      |> assign(per_page: @per_page)
      |> paginate_snapshots(1)
    }
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
    {:noreply, stream_insert(socket, :snapshots, snapshot, at: 0, limit: @per_page)}
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
          payload: %{snapshot_id: snapshot_id}
        },
        socket
      ) do
        
    snapshot = Archive.get_snapshot!(snapshot_id, socket.assigns.current_user)
    
    {:noreply, stream_insert(socket, :snapshots, snapshot, limit: @per_page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    snapshot = Archive.get_snapshot!(id, socket.assigns.current_user)
    {:ok, _} = Archive.delete_snapshot(snapshot)

    {:noreply, stream_delete(socket, :snapshots, snapshot)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    snapshots =
      Archive.list_snapshots(socket.assigns[:current_user],
        query: query,
        limit: @per_page,
        offset: 0
      )

    {:noreply, assign(socket, :search_query, query) |> stream(:snapshots, snapshots, reset: true)}
  end

  @impl true
  def handle_event("change_query", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def handle_event("reset_search", _params, socket) do
    snapshots =
      Archive.list_snapshots(socket.assigns[:current_user],
        query: nil,
        limit: @per_page,
        offset: 0
      )

    {:noreply, assign(socket, :search_query, nil) |> stream(:snapshots, snapshots, reset: true)}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_snapshots(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_snapshots(socket, 1)}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_snapshots(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("keyboard-shortcut", %{"key" => key}, socket) do
    case key do
      "/" ->
        {:noreply, push_event(socket, "focus_search_input", %{})}

      "n" ->
        {:noreply, push_patch(socket, to: ~p"/snapshots/new")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("refresh_snapshot", %{"sid" => snapshot_id}, socket) do
    snapshot = Archive.get_snapshot!(snapshot_id, socket.assigns[:current_user])

    case Archive.refresh_snapshot(snapshot) do
      {:ok, updated_snapshot} ->
        {:noreply, stream_insert(socket, :snapshots, updated_snapshot, limit: @per_page)}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply, socket}
    end

    {:noreply, socket |> put_flash(:info, "Triggering snapshot archive refresh.")}
  end

  defp paginate_snapshots(socket, new_page) when new_page >= 1 do
    %{page: cur_page, per_page: per_page, current_user: current_user} = socket.assigns

    snapshots =
      Archive.list_snapshots(current_user, offset: (new_page - 1) * per_page, limit: per_page)

    {snapshots, at, limit} =
      if new_page >= cur_page do
        {snapshots, -1, per_page * @overfetch_factor * -1}
      else
        {Enum.reverse(snapshots), 0, per_page * @overfetch_factor}
      end

    case snapshots do
      [] ->
        socket
        |> assign(end_of_timeline?: at == -1)

      _ ->
        socket
        |> assign(:end_of_timeline?, false)
        |> assign(:page, new_page)
    end
    |> stream(:snapshots, snapshots, at: at, limit: limit)
  end
end
