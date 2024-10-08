defmodule PhoenixVault.Archivers.ArchiverSupervisor do
  require Logger
  alias PhoenixVault.Archivers.ArchiverConfig
  alias PhoenixVault.Archivers.HtmlArchiver
  alias PhoenixVault.Archivers.ScreenshotArchiver
  alias PhoenixVault.Archivers.PdfArchiver
  use Supervisor

  def start_link(snapshot) do
    # TODO: Set unique name. Maybe base it on snapshot id
    Supervisor.start_link(__MODULE__, snapshot,
      name:
        {:via, Registry, {PhoenixVault.Archivers.Registry, {:archiver_supervisor, snapshot.id}}}
    )
  end

  @impl true
  def init(snapshot) do
    Logger.debug("Reached supervisor")

    # create per snapshot directory
    File.mkdir_p!(ArchiverConfig.snapshot_dir(snapshot.id))

    Logger.debug("Reached mkdir: #{inspect(ArchiverConfig.snapshot_dir(snapshot.id))}")

    children = [
      {PdfArchiver, snapshot},
      {ScreenshotArchiver, snapshot},
      {HtmlArchiver, snapshot}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
