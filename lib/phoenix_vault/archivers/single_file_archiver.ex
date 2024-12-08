defmodule PhoenixVault.Archivers.SingleFileArchiver do
  alias PhoenixVault.Archivers.ArchiverConfig
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Repo
  import Ecto.Query

  use Oban.Worker, max_attempts: 3

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    {:ok, body} = archive_as_single_file(snapshot_id, snapshot_url)

    summary =
      Readability.article(body)
      |> Readability.readable_text()

    {:ok, embedding} = OpenAIClient.get_embedding(summary)

    from(
      s in Snapshot,
      where: s.id == ^snapshot_id,
      update: [set: [is_single_file_saved: true, embedding: ^embedding]]
    )
    |> Repo.update_all([])

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id
    })

    {:ok, snapshot_id}
  end

  defp archive_as_single_file(snapshot_id, snapshot_url) do
    snapshot_dir = ArchiverConfig.snapshot_dir(snapshot_id)
    index_html_path = Path.join([snapshot_dir, "#{snapshot_id}.html"])

    command = "#{select_binary()} #{snapshot_url} #{index_html_path}"

    {_output, _exit_status} = System.cmd("sh", ["-c", command])
    # todo add error handling
    File.read!(index_html_path) |> extract_body()
  end

  defp extract_body(html) do
    {:ok, document} = Floki.parse_document(html)
    body = Floki.find(document, "body")
    {:ok, Floki.raw_html(body)}
  end

  defp select_binary do
    case :os.type() do
      {:unix, :darwin} -> "./bin/single-file-aarch64-apple-darwin"
      {:unix, _} -> "./bin/single-file-x86_64-linux"
      _ -> raise "Unsupported operating system"
    end
  end
end
