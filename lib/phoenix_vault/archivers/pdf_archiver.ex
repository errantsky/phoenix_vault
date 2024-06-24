defmodule PhoenixVault.Archivers.PdfArchiver do
  require Logger
  alias PhoenixVaultWeb.SnapshotLive
  alias PhoenixVault.Archive
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Archivers.ArchiverConfig
  use GenServer

  def start_link(snapshot) do
    # Generate a unique name based on snapshot id
    GenServer.start_link(__MODULE__, snapshot, name: {:global, {:pdf_archiver, snapshot.id}})
  end

  @impl true
  def init(snapshot) do
    Logger.debug("PdfArchiver: Starting for snapshot #{snapshot.id}")

    Task.start_link(fn ->
      Logger.debug("PdfArchiver: Creating PDF for snapshot #{snapshot.id}")
      print_pdf_for_url(snapshot)

      Logger.debug("PdfArchiver: Finished creating the PDF for snapshot #{snapshot.id}")

      case Archive.update_snapshot(snapshot, %{is_pdf_saved: true}) do
        {:ok, updated_snapshot} ->
          Logger.debug(
            "PdfArchiver: Snapshot updated successfully, broadcasting update for snapshot #{updated_snapshot.id}"
          )

          PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
            snapshot: updated_snapshot,
            updated_field: "is_pdf_saved"
          })

        {:error, %Ecto.Changeset{} = changeset} ->
          Logger.error(
            "PdfArchiver: Failed to update the snapshot #{snapshot.id}: #{inspect(changeset)}"
          )
      end
    end)

    {:ok, snapshot}
  end

  defp print_pdf_for_url(%Snapshot{} = snapshot) do
    ChromicPDF.print_to_pdfa({:url, snapshot.url},
      output: Path.join(ArchiverConfig.snapshot_dir(snapshot), "#{snapshot.id}.pdf")
    )
  end
end
