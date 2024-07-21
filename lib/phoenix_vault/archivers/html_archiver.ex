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
      embedding = OpenAIClient.get_embedding(body)
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
  
    {_, 0} = System.cmd("sh", ["-c", archive_command])
    
    snapshot_dir = ArchiverConfig.snapshot_dir(snapshot)
    index_html_path = Path.join([snapshot_dir, "index.html"])
  
    if File.exists?(index_html_path) do
      {:ok, html} = File.read(index_html_path)
      extract_body(html)
    else
      {:error, "HTML file not found"}
    end
  end
  
  defp extract_body(html) do
    {:ok, document} = Floki.parse_document(html)
    body = Floki.find(document, "body")
    {:ok, Floki.raw_html(body)}
  end

end
