defmodule PhoenixVault.Archivers.ArchiverSupervisor do
  alias PhoenixVault.Archivers.PdfArchiver
  use Supervisor
  
  def start_link(snapshot) do
    Supervisor.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    children = [
      {PdfArchiver, snapshot}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
