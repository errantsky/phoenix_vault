defmodule PhoenixVault.Archivers.HtmlArchiver do
  alias PhoenixVault.Snapshot
  alias PhoenixVault.Archivers.ArchiverConfig
  use GenServer

  def start_link(snapshot) do
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Task.start_link(fn -> archive_as_html(snapshot) end)

    {:ok, snapshot}
  end

  defp archive_as_html(%Snapshot{} = snapshot) do
    archive_command =
      "wget --convert-links --adjust-extension --page-requisites #{snapshot.url} -P #{ArchiverConfig.snapshot_dir(snapshot)}"

    System.cmd("sh", ["-c", archive_command])
  end
end
