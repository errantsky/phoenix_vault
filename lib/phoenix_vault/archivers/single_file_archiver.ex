defmodule SingleFileArchiver do
  use Oban.Worker, max_attempts: 3

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    {:ok, _ret} = archive_as_single_file(snapshot_id, snapshot_url)

    {:ok, embedding} = OpenAIClient.get_embedding(body)

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id,
      update_columns: %{is_single_file_saved: true, embedding: embedding}
    })

    {:ok, snapshot_id}
  end

  defp archive_as_single_file(snapshot_id, snapshot_url) do
    snapshot_dir = ArchiverConfig.snapshot_dir(snapshot_id)
    index_html_path = Path.join([snapshot_dir, snapshot_id])

    command = """
      ./singlefile #{snapshot_url} #{index_html_path}
    """

    [_output, _exit_status] = System.cmd("sh", ["-c", command])

    # todo add error handling
    {:ok, html} = File.read(Path.join([index_html_path, snapshot_id <> ".html"])
  end

  defp find_index_html(snapshot_dir) do
    # todo simplify
    Path.wildcard(Path.join([snapshot_dir, "**", "index.html"]))
    |> List.first()
  end
end
