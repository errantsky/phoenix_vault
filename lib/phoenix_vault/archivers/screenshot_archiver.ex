defmodule PhoenixVault.Archivers.ScreenshotArchiver do
  use Oban.Worker
  require Logger
  alias PhoenixVault.Archivers.ArchiverConfig

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    Logger.debug("ScreenshotArchiver: Starting for snapshot #{snapshot_id}")

    Logger.debug("ScreenshotArchiver: Creating screenshot for snapshot #{snapshot_id}")
    save_screenshot(snapshot_id, snapshot_url)

    Logger.debug(
      "ScreenshotArchiver: Finished creating the screenshot for snapshot #{snapshot_id}"
    )

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id,
      updated_columns: %{is_screenshot_saved: true}
    })

    {:ok, snapshot_id}
  end

  defp save_screenshot(snapshot_id, snapshot_url) do
    ChromicPDF.capture_screenshot({:url, snapshot_url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot_id), "#{snapshot_id}.png"),
      full_page: true
    )
  end
end
