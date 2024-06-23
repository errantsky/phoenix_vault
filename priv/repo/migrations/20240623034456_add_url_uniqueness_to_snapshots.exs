defmodule PhoenixVault.Repo.Migrations.AddUrlUniquenessToSnapshots do
  use Ecto.Migration

  def change do
    create unique_index(:snapshots, :url)
  end
end
