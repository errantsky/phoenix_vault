defmodule PhoenixVaultWeb.SnapshotLive.BulkSnapshotComponent do
  use PhoenixVaultWeb, :live_component

  alias PhoenixVault.Archive
  alias PhoenixVault.Schemas.Snapshot

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to bulk create snapshot records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="bulk-snapshot-form"
        phx-target={@myself}
        phx-submit="bulk_save"
      >
        <.input field={@form[:urls]} label="URLs" type="textarea" required />
        <:actions>
          <.button phx-disable-with="Saving...">Save Snapshots</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # @impl true
  # def update(%{snapshot: snapshot} = assigns, socket) do
  #   changeset = Archive.change_snapshot(snapshot)

  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign_form(changeset)}
  # end

  # @impl true
  # def handle_event("validate", %{"snapshot" => snapshot_params}, socket) do
  #   changeset =
  #     socket.assigns.snapshot
  #     |> Archive.change_snapshot(snapshot_params)
  #     |> Map.put(:action, :validate)

  #   {:noreply, assign_form(socket, changeset)}
  # end

  def handle_event("bulk_save", %{"urls" => urls}, socket) do
    save_snapshot(socket, socket.assigns.action, urls)
  end

  defp save_snapshot(socket, :new, urls) do
    case Archive.bulk_create_snapshots(urls) do
      {:ok, grouped_snapshots} ->
        notify_parent({:saved, grouped_snapshots[:ok]})

        {:noreply,
         socket
         |> put_flash(:info, "Snapshot created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, grouped_snapshots} ->
        Logger.debug("save_snapshot :new could not insert any new snapshots.")
        {:noreply, assign_form(socket, grouped_snapshots[:error])}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
