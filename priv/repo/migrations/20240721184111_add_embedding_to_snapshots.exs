defmodule PhoenixVault.Repo.Migrations.AddEmbeddingToSnapshots do
  use Ecto.Migration

  def change do
    alter table(:snapshots) do
      add :embedding, :vector, size: 1536
    end
  end
end
