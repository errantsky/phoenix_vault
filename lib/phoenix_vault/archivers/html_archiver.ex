defmodule PhoenixVault.Archivers.HtmlArchiver do
  require Logger
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Archivers.ArchiverConfig
  use GenServer

  def start_link(snapshot) do
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Logger.debug("HtmlArchiver: Starting for snapshot #{snapshot.id}")

    Task.start_link(fn ->
      Logger.debug("HtmlArchiver: Creating HTML for snapshot #{snapshot.id}")
      # todo handle error
      {:ok, body} = archive_as_html(snapshot)
      Logger.debug("HtmlArchiver: Finished creating the HTML for snapshot #{snapshot.id}")


      Logger.debug("HtmlArchiver: Creating embedding for snapshot #{snapshot.id}")
      {:ok, embedding} = OpenAIClient.get_embedding(body)
      Logger.debug("HtmlArchiver: Finished creating the embedding for snapshot #{snapshot.id}")

      PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
        snapshot_id: snapshot.id,
        updated_columns: %{is_html_saved: true, embedding: embedding}
      })
    end)

    {:ok, snapshot}
  end

  defp archive_as_html(%Snapshot{} = snapshot) do
    archive_command =
      "wget --convert-links --adjust-extension --page-requisites #{snapshot.url} -P #{ArchiverConfig.snapshot_dir(snapshot)}"

      # TODO 0 and other vals
      {_, exit_status} = System.cmd("sh", ["-c", archive_command])

    snapshot_dir = ArchiverConfig.snapshot_dir(snapshot)
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
