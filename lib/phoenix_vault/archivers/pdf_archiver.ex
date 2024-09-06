defmodule PhoenixVault.Archivers.PdfArchiver do
  require Logger
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Archivers.ArchiverConfig
  use GenServer

  def start_link(snapshot) do
    GenServer.start_link(__MODULE__, snapshot,
      name: {:via, Registry, {PhoenixVault.Archivers.Registry, {:pdf_archiver, snapshot.id}}}
    )
  end

  @impl true
  def init(snapshot) do
    Logger.debug("PdfArchiver: Starting for snapshot #{snapshot.id}")

    # todo add error handling
    Task.start_link(fn ->
      Logger.debug("PdfArchiver: Creating PDF for snapshot #{snapshot.id}")
      print_pdf_for_url(snapshot)

      Logger.debug("PdfArchiver: Finished creating the PDF for snapshot #{snapshot.id}")

      PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
        snapshot_id: snapshot.id,
        updated_columns: %{is_pdf_saved: true}
      })
    end)

    {:ok, snapshot}
  end

  defp print_pdf_for_url(%Snapshot{} = snapshot) do
    ChromicPDF.print_to_pdfa({:url, snapshot.url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot), "#{snapshot.id}.pdf")
    )
  end
end
