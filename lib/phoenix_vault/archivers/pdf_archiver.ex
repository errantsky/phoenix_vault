defmodule PhoenixVault.Archivers.PdfArchiver do
  use GenServer

  def start_link(snapshot) do
    GenServer.start_link(__MODULE__, snapshot, name: __MODULE__)
  end

  @impl true
  def init(snapshot) do
    Task.start_link(fn -> print_pdf_for_url(snapshot) end)

    {:ok, snapshot}
  end

  defp print_pdf_for_url(%{url: url, id: id}) do
    ChromicPDF.print_to_pdf({:url, url},
      output: Path.join("priv/archive", "#{id}.pdf")
    )
  end
end
