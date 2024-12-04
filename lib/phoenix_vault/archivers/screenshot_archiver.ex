defmodule PhoenixVault.Archivers.ScreenshotArchiver do
  alias PhoenixVault.Archivers.ArchiverConfig
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Repo
  import Ecto.Query

  use Oban.Worker, max_attempts: 3

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    save_screenshot(snapshot_id, snapshot_url)

    from(
      s in Snapshot,
      where: s.id == ^snapshot_id,
      update: [set: [is_screenshot_saved: true,]]
    )
      |> Repo.update_all([])

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id
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
