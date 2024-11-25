defmodule PhoenixVault.Schemas.Snapshot do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :title, :url, :tags]}
  schema "snapshots" do
    field :title, :string
    field :url, :string
    field :is_html_saved, :boolean, default: false
    field :is_screenshot_saved, :boolean, default: false
    field :is_pdf_saved, :boolean, default: false
    field :is_single_file_saved, :boolean, default: false
    field :user_id, :integer
    field :embedding, Pgvector.Ecto.Vector
    
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
    |> cast(attrs, [:title, :url, :user_id, :is_pdf_saved, :is_screenshot_saved, :is_html_saved, :is_single_file_saved, :embedding])
    |> validate_required([:title, :url, :user_id])
    |> unique_constraint(:url)
    |> put_assoc(:tags, Map.get(attrs, "tags", []))
    |> update_change(:url, &String.trim/1)
  end
end
