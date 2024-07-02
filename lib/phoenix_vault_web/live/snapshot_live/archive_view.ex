defmodule PhoenixVaultWeb.SnapshotLive.ArchiveView do
  require Logger
  alias PhoenixVault.Archive
  use PhoenixVaultWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {
      :noreply,
      socket
      |> assign(:page_title, "Archive View")
      |> assign(:snapshot, Archive.get_snapshot!(id))
    }
  end
end
