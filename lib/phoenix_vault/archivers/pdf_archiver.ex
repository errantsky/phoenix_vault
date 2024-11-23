defmodule PhoenixVault.Archivers.PdfArchiver do
  use Oban.Worker
  require Logger
  alias PhoenixVault.Archivers.ArchiverConfig

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do

    # todo add error handling
    print_pdf_for_url(snapshot_id, snapshot_url)

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id,
      updated_columns: %{is_pdf_saved: true}
    })

    {:ok, snapshot_id}
  end

  defp print_pdf_for_url(snapshot_id, snapshot_url) do
    ChromicPDF.print_to_pdfa({:url, snapshot_url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot_id), "#{snapshot_id}.pdf")
    )
  end
end
