defmodule PhoenixVault.Archivers.ScreenshotArchiver do
  use GenServer

  def start_link(snapshot) do
    # TODO: Set unique name. Maybe base it on snapshot id
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Task.start_link(fn -> save_screenshot(snapshot) end)

    {:ok, snapshot}
  end

  defp save_screenshot(%{id: id, url: url}) do
    ChromicPDF.capture_screenshot({:url, url},
      output: Path.join("priv/archive", "#{id}.png"),
      full_page: true
    )
  end
end
