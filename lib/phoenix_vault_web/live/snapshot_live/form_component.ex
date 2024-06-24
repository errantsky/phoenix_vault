defmodule PhoenixVaultWeb.SnapshotLive.FormComponent do
  use PhoenixVaultWeb, :live_component

  alias PhoenixVault.Archive

  require Logger

  defp tag_list_to_string(tags) when is_list(tags) do
    Enum.map(tags, fn tag -> tag.name end) |> Enum.join(",")
  end

  @impl true
  def render(assigns) do
    Logger.debug("assigns: #{inspect(assigns, pretty: true)}")

    tag_names = tag_list_to_string(assigns[:snapshot].tags)

    Logger.debug("tag_names: #{tag_names}")

    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage snapshot records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="snapshot-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} label="Title" type="text" required />
        <.input field={@form[:url]} label="URL" type="text" required />
        <.input field={@form[:tags]} label="Tags" type="text" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Snapshot</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{snapshot: snapshot} = assigns, socket) do
    changeset = Archive.change_snapshot(snapshot)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"snapshot" => snapshot_params}, socket) do
    changeset =
      socket.assigns.snapshot
      |> Archive.change_snapshot(snapshot_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"snapshot" => snapshot_params}, socket) do
    save_snapshot(socket, socket.assigns.action, snapshot_params)
  end

  defp save_snapshot(socket, :edit, snapshot_params) do
    case Archive.update_snapshot(socket.assigns.snapshot, snapshot_params) do
      {:ok, snapshot} ->
        notify_parent({:saved, snapshot})

        {:noreply,
         socket
         |> put_flash(:info, "Snapshot updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_snapshot(socket, :new, snapshot_params) do
    case Archive.create_snapshot(snapshot_params) do
      {:ok, snapshot} ->
        notify_parent({:saved, snapshot})

        {:noreply,
         socket
         |> put_flash(:info, "Snapshot created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
