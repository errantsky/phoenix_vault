defmodule PhoenixVault.Archivers.PdfArchiver do
  alias PhoenixVault.Snapshot
  alias PhoenixVault.Archivers.ArchiverConfig
  use GenServer

  def start_link(snapshot) do
    # TODO: Set unique name. Maybe base it on snapshot id
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Task.start_link(fn -> print_pdf_for_url(snapshot) end)

    {:ok, snapshot}
  end

  defp print_pdf_for_url(%Snapshot{} = snapshot) do
    ChromicPDF.print_to_pdfa({:url, snapshot.url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot), "#{snapshot.id}.pdf")
    )
  end
end
