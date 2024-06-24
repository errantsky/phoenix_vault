defmodule PhoenixVault.Schemas.Snapshot do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset

  schema "snapshots" do
    field :title, :string
    field :url, :string
    field :is_html_saved, :boolean
    field :is_screenshot_saved, :boolean
    field :is_pdf_saved, :boolean

    many_to_many :tags, PhoenixVault.Schemas.Tag,
      join_through: PhoenixVault.Schemas.SnapshotTag,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snapshot, attrs) do
    # TODO validate url
    # TODO validate tags
    snapshot
    |> cast(attrs, [:title, :url, :is_pdf_saved, :is_screenshot_saved, :is_html_saved])
    |> validate_required([:title, :url])
    |> unique_constraint(:url)
    |> put_assoc(:tags, Map.get(attrs, "tags", []))
  end
end
