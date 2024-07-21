defmodule PhoenixVault.Archivers.ScreenshotArchiver do
  require Logger
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

      Logger.debug(
        "ScreenshotArchiver: Finished creating the screenshot for snapshot #{snapshot.id}"
      )

      PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
        snapshot_id: snapshot.id,
        updated_columns: %{is_screenshot_saved: true}
      })
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
