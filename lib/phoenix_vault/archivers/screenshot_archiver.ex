defmodule PhoenixVault.Archivers.ScreenshotArchiver do
  require Logger
  alias PhoenixVault.Archive
  alias PhoenixVault.Archivers.ArchiverConfig
  alias PhoenixVault.Schemas.Snapshot
  use GenServer

  def start_link(snapshot) do
    # TODO: Set unique name. Maybe base it on snapshot id
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  def init(snapshot) do
    Logger.debug("ScreenshotArchiver: Starting for snapshot #{snapshot.id}")
    Task.start_link(fn ->
      Logger.debug("ScreenshotArchiver: Creating screenshot for snapshot #{snapshot.id}")
      save_screenshot(snapshot)

      Logger.debug("ScreenshotArchiver: Finished creating the screenshot for snapshot #{snapshot.id}")
      case Archive.update_snapshot(snapshot, %{is_screenshot_saved: true}) do
        {:ok, updated_snapshot} ->
          Logger.debug("ScreenshotArchiver: Snapshot updated successfully, broadcasting update for snapshot #{updated_snapshot.id}")
          PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
            snapshot: updated_snapshot,
            updated_field: "is_pdf_saved"
          })
        {:error, %Ecto.Changeset{} = changeset} ->
          Logger.error("ScreenshotArchiver: Failed to update the snapshot #{snapshot.id}: #{inspect(changeset)}")
      end
    end)

    {:ok, snapshot}
  end

  defp save_screenshot(%Snapshot{} = snapshot) do
    ChromicPDF.capture_screenshot({:url, snapshot.url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot), "#{snapshot.id}.png"),
      full_page: true
    )
  end
end
