defmodule PhoenixVault.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "snapshots" do
    field :title, :string
    field :url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:title, :url])
    |> validate_required([:title, :url])
    |> unique_constraint(:url)
  end
end
