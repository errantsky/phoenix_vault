defmodule PhoenixVault.Archivers.SingleFileArchiver do
  alias PhoenixVault.Archivers.ArchiverConfig
  use Oban.Worker, max_attempts: 3

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    {:ok, body} = archive_as_single_file(snapshot_id, snapshot_url)

    {:ok, embedding} = OpenAIClient.get_embedding(body)

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id,
      update_columns: %{is_single_file_saved: true, embedding: embedding}
    })

    {:ok, snapshot_id}
  end

  defp archive_as_single_file(snapshot_id, snapshot_url) do
    snapshot_dir = ArchiverConfig.snapshot_dir(snapshot_id)
    index_html_path = Path.join([snapshot_dir, "#{snapshot_id}.html"])

    command = "./bin/single-file-m #{snapshot_url} #{index_html_path}"

    dbg(command)

    {_output, _exit_status} = System.cmd("sh", ["-c", command])

    # todo add error handling
    File.read!(index_html_path) |> extract_body()
  end

  defp extract_body(html) do
    {:ok, document} = Floki.parse_document(html)
    body = Floki.find(document, "body")
    {:ok, Floki.raw_html(body)}
  end
end
