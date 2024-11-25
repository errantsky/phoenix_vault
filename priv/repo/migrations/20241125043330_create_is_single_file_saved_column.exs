defmodule PhoenixVault.Repo.Migrations.CreateIsSingleFileSavedColumn do
  use Ecto.Migration

  def change do
    alter table(:snapshots) do
      add :is_single_file_saved, :boolean, default: false
    end
  end
end
