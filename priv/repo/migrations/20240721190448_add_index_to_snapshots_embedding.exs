defmodule PhoenixVault.Repo.Migrations.AddIndexToSnapshotsEmbedding do
  use Ecto.Migration

  def change do
    create index(:snapshots, ["embedding vector_cosine_ops"], using: :hnsw)
  end
end
