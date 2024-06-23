defmodule PhoenixVault.Repo.Migrations.CreateSnapshotTagsJoinTable do
  use Ecto.Migration

  def change do
    create table(:snapshot_tags, primary_key: false) do
      add :snapshot_id, references(:snapshots, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:snapshot_tags, [:snapshot_id, :tag_id])
  end
end
