defmodule PhoenixVault.Archivers.HtmlArchiver do
  require Logger
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Archivers.ArchiverConfig
  use GenServer

  def start_link(snapshot) do
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Logger.debug("HtmlArchiver: Starting for snapshot #{snapshot.id}")

    Task.start_link(fn ->
      Logger.debug("HtmlArchiver: Creating HTML for snapshot #{snapshot.id}")
      archive_as_html(snapshot)

      Logger.debug("HtmlArchiver: Finished creating the HTML for snapshot #{snapshot.id}")

      PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
        snapshot_id: snapshot.id,
        updated_column: :is_html_saved
      })
    end)

    {:ok, snapshot}
  end

  defp archive_as_html(%Snapshot{} = snapshot) do
    archive_command =
      "wget --convert-links --adjust-extension --page-requisites #{snapshot.url} -P #{ArchiverConfig.snapshot_dir(snapshot)}"

    System.cmd("sh", ["-c", archive_command])
  end
end
