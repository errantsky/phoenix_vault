defmodule PhoenixVault.Schemas.SnapshotTag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "snapshot_tags" do
    belongs_to :snapshot, PhoenixVault.Schemas.Snapshot
    belongs_to :tag, PhoenixVault.Schemas.Tag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snapshot_tag, attrs) do
    snapshot_tag
    |> cast(attrs, [:snapshot, :tag])
    |> validate_required([:snapshot, :tag])
    |> put_change(:inserted_at, NaiveDateTime.utc_now())
    |> put_change(:updated_at, NaiveDateTime.utc_now())
  end
end
