defmodule PhoenixVault.Repo.Migrations.AddUserIdToSnapshots do
  use Ecto.Migration

  def change do
    alter table(:snapshots) do
      add :user_id, :integer
    end
  end
end
