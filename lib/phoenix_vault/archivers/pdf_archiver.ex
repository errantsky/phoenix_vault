defmodule PhoenixVault.Archivers.PdfArchiver do
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Repo
  alias PhoenixVault.Archivers.ArchiverConfig
  import Ecto.Query
  
  use Oban.Worker, max_attempts: 3

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    # todo add error handling
    print_pdf_for_url(snapshot_id, snapshot_url)
    
    from(
      s in Snapshot,
      where: s.id == ^snapshot_id,
      update: [set: [is_pdf_saved: true]]
    )
    |> Repo.update_all([])

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id
    })

    {:ok, snapshot_id}
  end

  defp print_pdf_for_url(snapshot_id, snapshot_url) do
    ChromicPDF.print_to_pdfa({:url, snapshot_url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot_id), "#{snapshot_id}.pdf")
    )
  end
end
