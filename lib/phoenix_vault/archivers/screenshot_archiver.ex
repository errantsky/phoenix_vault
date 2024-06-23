defmodule PhoenixVault.Archivers.ScreenshotArchiver do
  require Logger
  alias PhoenixVault.Archivers.ArchiverConfig
  alias PhoenixVault.Schemas.Snapshot
  use GenServer

  def start_link(snapshot) do
    # TODO: Set unique name. Maybe base it on snapshot id
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Logger.debug("Reached save_screenshot")
    Task.start_link(fn -> save_screenshot(snapshot) end)

    {:ok, snapshot}
  end

  defp save_screenshot(%Snapshot{} = snapshot) do
    ChromicPDF.capture_screenshot({:url, snapshot.url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot), "#{snapshot.id}.png"),
      full_page: true
    )
  end
end
