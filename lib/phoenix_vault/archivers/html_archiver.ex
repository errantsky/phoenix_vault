defmodule PhoenixVault.Archivers.HtmlArchiver do
  use Oban.Worker
  require Logger
  alias PhoenixVault.Archivers.ArchiverConfig

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    
    # todo handle error
    {:ok, body} = archive_as_html(snapshot_id, snapshot_url)

    {:ok, embedding} = OpenAIClient.get_embedding(body)

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id,
      updated_columns: %{is_html_saved: true, embedding: embedding}
    })

    {:ok, snapshot_id}
  end

  defp archive_as_html(snapshot_id, snapshot_url) do
    archive_command =
      "wget --no-parent --convert-links --adjust-extension --page-requisites --reject=*.js #{snapshot_url} -P #{ArchiverConfig.snapshot_dir(snapshot_id)}"


    {_output, _exit_status} = System.cmd("sh", ["-c", archive_command])

    # Now continue with the rest of the logic
    snapshot_dir = ArchiverConfig.snapshot_dir(snapshot_id)
    index_html_path = find_index_html(snapshot_dir)

    case index_html_path do
      nil ->
        {:error, "HTML file not found"}

      index_html_path ->
        {:ok, html} = File.read(index_html_path)
        extract_body(html)
    end
  end

  defp extract_body(html) do
    {:ok, document} = Floki.parse_document(html)
    body = Floki.find(document, "body")
    {:ok, Floki.raw_html(body)}
  end

  defp find_index_html(snapshot_dir) do
    Path.wildcard(Path.join([snapshot_dir, "**", "index.html"]))
    |> List.first()
  end
end
