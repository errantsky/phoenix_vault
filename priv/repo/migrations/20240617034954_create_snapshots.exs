defmodule PhoenixVault.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots) do
      add :title, :string
      add :url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
