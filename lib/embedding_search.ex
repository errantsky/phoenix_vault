defmodule EmbeddingSearch do
  import Ecto.Query
  import Pgvector.Ecto.Query
  alias PhoenixVault.Schemas.Snapshot
  alias PhoenixVault.Repo

  def find_similar_snapshots(snapshot, user_id, limit \\ 5) do
    Repo.all(
      from i in Snapshot,
        where: i.id != ^snapshot.id and i.user_id == ^user_id,
        select: [i.id, i.title, i.url],
        order_by: cosine_distance(i.embedding, ^snapshot.embedding),
        limit: ^limit
    )
  end

  def find_snapshots_from_query(snapshot_content, user_id, limit \\ 5) do
    {:ok, snapshot_embedding} = OpenAIClient.get_embedding(snapshot_content)

    Repo.all(
      from s in Snapshot,
        where: s.user_id == ^user_id,
        order_by: cosine_distance(s.embedding, ^snapshot_embedding),
        limit: ^limit
    )
    |> Repo.preload(:tags)
  end
end
