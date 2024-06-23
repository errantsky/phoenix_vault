defmodule PhoenixVault.Archivers.ArchiverSupervisor do
  alias PhoenixVault.Archivers.ScreenshotArchiver
  alias PhoenixVault.Archivers.PdfArchiver
  use Supervisor
  
  def start_link(snapshot) do
    # TODO: Set unique name. Maybe base it on snapshot id
    Supervisor.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    children = [
      {PdfArchiver, snapshot},
      {ScreenshotArchiver, snapshot}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
