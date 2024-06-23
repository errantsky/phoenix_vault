defmodule PhoenixVault.Archivers.PdfArchiver do
  use GenServer

  def start_link(snapshot) do
    # TODO: Set unique name. Maybe base it on snapshot id
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Task.start_link(fn -> print_pdf_for_url(snapshot) end)

    {:ok, snapshot}
  end

  defp print_pdf_for_url(%{url: url, id: id}) do
    ChromicPDF.print_to_pdfa({:url, url},
      output: Path.join("priv/archive", "#{id}.pdf")
    )
  end
end
