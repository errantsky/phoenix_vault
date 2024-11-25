defmodule PhoenixVault.Archivers.SingleFileArchiver do
  alias PhoenixVault.Archivers.ArchiverConfig
  use Oban.Worker, max_attempts: 3

  @impl Worker
  def perform(%Job{args: %{"snapshot_id" => snapshot_id, "snapshot_url" => snapshot_url}}) do
    {:ok, body} = archive_as_single_file(snapshot_id, snapshot_url)

    {:ok, embedding} = OpenAIClient.get_embedding(body)

    PhoenixVaultWeb.Endpoint.broadcast!("snapshots", "archiver_update", %{
      snapshot_id: snapshot_id,
      updated_columns: %{is_single_file_saved: true, embedding: embedding}
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
