defmodule PhoenixVault.Repo.Migrations.AddArchiveStatusToSnapshots do
  use Ecto.Migration

  def change do
    alter table(:snapshots) do
      add :is_html_saved, :boolean, default: false
      add :is_pdf_saved, :boolean, default: false
      add :is_screenshot_saved, :boolean, default: false
    end
  end
end
