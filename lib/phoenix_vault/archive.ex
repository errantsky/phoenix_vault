defmodule PhoenixVault.Archive do
  @moduledoc """
  The Archive context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias PhoenixVault.Archivers
  alias Ecto.Changeset
  alias PhoenixVault.Schemas.Tag
  alias PhoenixVault.Repo

  alias PhoenixVault.Schemas.Snapshot

  @per_page 20
  @overfetch_factor 3

  def snapshot_table_per_page do
    @per_page
  end

  def snapshot_table_overfetch_factor do
    @overfetch_factor
  end

  @doc """
  Returns a page's worth of snapshots. Used in the index LiveView's infinite snapshots stream.
  """
  def list_snapshots(current_user, opts \\ []) do
    opts = Keyword.merge([offset: 0, limit: @per_page, query: nil], opts)
    offset = Keyword.get(opts, :offset)
    limit = Keyword.get(opts, :limit)
    query = Keyword.get(opts, :query)
    Logger.debug("paginate_snapshots: started.")

    if query do
      EmbeddingSearch.find_snapshots_from_query(query, current_user.id, @per_page)
    else
      Repo.all(
        from s in Snapshot,
          where: s.user_id == ^current_user.id,
          order_by: [desc: s.inserted_at],
          offset: ^offset,
          limit: ^limit
      )
      |> Repo.preload(:tags)
    end
  end

  @doc """
  Gets a single snapshot.

  Raises if the Snapshot does not exist.

  ## Examples

      iex> get_snapshot!(123)
      %Snapshot{}

  """
  def get_snapshot!(id, current_user) do
    # todo error handling
    if current_user == nil do
      Repo.get_by!(Snapshot, id: id)
    else
      Repo.get_by!(Snapshot, id: id, user_id: current_user.id)
    end
    |> Repo.preload(:tags)
  end

  @doc """
  Finds the first snapshot saved after the one currently being viewed

  """
  def get_next_snapshot(snapshot) do
    Repo.one(
      from s in Snapshot,
        where: s.inserted_at > ^snapshot.inserted_at and s.user_id == ^snapshot.user_id,
        order_by: [asc: s.inserted_at],
        limit: 1
    )
    |> Repo.preload(:tags)
  end

  @doc """
  Finds the first snapshot saved before the one currently being viewed
  """
  def get_prev_snapshot(snapshot) do
    Repo.one(
      from s in Snapshot,
        where: s.inserted_at < ^snapshot.inserted_at and s.user_id == ^snapshot.user_id,
        order_by: [desc: s.inserted_at],
        limit: 1
    )
    |> Repo.preload(:tags)
  end

  @doc """
  Creates a snapshot.

  ## Examples

      iex> create_snapshot(%{field: value})
      {:ok, %Snapshot{}}

      iex> create_snapshot(%{field: bad_value})
      {:error, ...}

  """
  def create_snapshot(attrs \\ %{}, current_user, delay_archiving \\ false) do
    # Process the snapshot creation logic
    tags =
      case attrs["tags"] do
        nil ->
          []

        _ ->
          String.split(attrs["tags"], ",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(fn name -> %Tag{name: name} end)
      end

    %Snapshot{}
    |> Snapshot.changeset(%{
      url: attrs["url"],
      title: attrs["title"],
      user_id: current_user.id,
      tags: tags
    })
    |> Repo.insert()
    |> case do
      {:ok, snapshot} ->
        Logger.debug("Successfully created the snapshot.")
        Logger.debug("Archive create_snapshot: starteing to queue the archiver jobs with Oban")

        if delay_archiving || Application.get_env(:phoenix_vault, :archiver_enabled) != "true" do
          {:ok, snapshot}
        else
          Ecto.Multi.new()
          |> Oban.insert(
            "pdf-archiver-#{snapshot.id}",
            Archivers.PdfArchiver.new(%{snapshot_id: snapshot.id, snapshot_url: snapshot.url})
          )
          |> Oban.insert(
            "html-archiver-#{snapshot.id}",
            Archivers.HtmlArchiver.new(%{snapshot_id: snapshot.id, snapshot_url: snapshot.url})
          )
          |> Oban.insert(
            "screenshot-archiver-#{snapshot.id}",
            Archivers.ScreenshotArchiver.new(%{
              snapshot_id: snapshot.id,
              snapshot_url: snapshot.url
            })
          )
          |> PhoenixVault.Repo.transaction()

          Logger.debug("Archive create_snapshot: finished queueing the archiver jobs with Oban")

          # Return the created snapshot, immediately responding to the API request
          {:ok, snapshot}
        end

      {:error, changeset} ->
        Logger.debug("Snapshot creation failed: #{inspect(changeset)}")
        {:error, changeset}
    end
  end

  @doc """
  Refreshed a snapshot's archives.

  ## Examples

      iex> refresh_snapshot(%{field: value})
      {:ok, %Snapshot{}}

      iex> refresh_snapshot(%{field: bad_value})
      {:error, ...}

  """
  def refresh_snapshot(snapshot) do
    Logger.debug("Archive: Refreshing snapshot")

    File.rm_rf!(Archivers.ArchiverConfig.snapshot_dir(snapshot.id))

    # reset archive icons
    case update_snapshot(snapshot, %{
           is_screenshot_saved: false,
           is_pdf_saved: false,
           is_html_saved: false
         }) do
      {:ok, updated_snapshot} ->
        Ecto.Multi.new()
        |> Oban.insert(
          "pdf-archiver-#{updated_snapshot.id}",
          Archivers.PdfArchiver.new(%{
            snapshot_id: updated_snapshot.id,
            snapshot_url: updated_snapshot.url
          })
        )
        |> Oban.insert(
          "html-archiver-#{updated_snapshot.id}",
          Archivers.HtmlArchiver.new(%{
            snapshot_id: updated_snapshot.id,
            snapshot_url: updated_snapshot.url
          })
        )
        |> Oban.insert(
          "screenshot-archiver-#{snapshot.id}",
          Archivers.ScreenshotArchiver.new(%{
            snapshot_id: updated_snapshot.id,
            snapshot_url: updated_snapshot.url
          })
        )
        |> PhoenixVault.Repo.transaction()

        Logger.debug("Archive refresh_snapshot: finished queueing the archiver jobs with Oban")

        {:ok, updated_snapshot}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Archive refresh snapshot failed to reset archive statuses.")
        {:noreply, changeset}
    end
  end

  @doc """
  Creates multiple snapshots

  ## Example

    iex> bulk_create_snapshots(%{urls: ["https://google.com", "https://kagi.com"]}

  TODO
  """

  def bulk_create_snapshots(attrs \\ %{}) do
    # todo add error handling
    # todo add tags
    grouped_insert_results =
      attrs["urls"]
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn url -> %Snapshot{title: url, url: url} end)
      |> Enum.map(fn snapshot -> Repo.insert(snapshot) end)
      |> Enum.group_by(
        fn insert_result ->
          case insert_result do
            {:ok, %Snapshot{}} ->
              :ok

            {:error, %Changeset{}} ->
              # todo raise the failed cases, or log store them somewhere
              :error
          end
        end,
        fn insert_result ->
          case insert_result do
            {:ok, snapshot} ->
              snapshot

            {:error, changeset} ->
              changeset
          end
        end
      )

    Logger.debug("bulk_create_snapshots result: #{inspect(grouped_insert_results, pretty: true)}")

    if Enum.empty?(grouped_insert_results[:ok]) do
      {:error, grouped_insert_results}
    else
      {:ok, grouped_insert_results}
    end
  end

  @doc """
  Updates a snapshot.

  ## Examples

      iex> update_snapshot(snapshot, %{field: new_value})
      {:ok, %Snapshot{}}

      iex> update_snapshot(snapshot, %{field: bad_value})
      {:error, ...}

  """
  def update_snapshot(%Snapshot{} = snapshot, attrs) do
    tag_structs =
      case Map.get(attrs, "tags") do
        nil ->
          snapshot.tags

        tags ->
          tags
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(fn name -> %Tag{name: name} end)
      end

    # Ensure all keys in attrs are strings
    attrs = attrs |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
    attrs = Map.put(attrs, "tags", tag_structs)

    snapshot = Repo.preload(snapshot, :tags)
    changeset = Snapshot.changeset(snapshot, attrs)

    case Repo.update(changeset) do
      {:ok, updated_snapshot} ->
        {:ok, updated_snapshot}

      {:error, changeset} ->
        Logger.debug("error is: #{inspect(changeset)}")
        {:error, changeset}
    end
  end

  def update_archiver_status(%Snapshot{} = snapshot, attrs) do
    snapshot = Repo.preload(snapshot, :tags)
    changeset = Snapshot.changeset(snapshot, attrs)

    case Repo.update(changeset) do
      {:ok, updated_snapshot} ->
        {:ok, updated_snapshot}

      {:error, changeset} ->
        Logger.debug("update_archiver_status: error is: #{inspect(changeset)}")
        {:error, changeset}
    end
  end

  @doc """
  Deletes a Snapshot.

  ## Examples

      iex> delete_snapshot(snapshot)
      {:ok, %Snapshot{}}

      iex> delete_snapshot(snapshot)
      {:error, ...}

  """
  def delete_snapshot(%Snapshot{} = snapshot) do
    Repo.delete(snapshot)
  end

  @doc """
  Returns a data structure for tracking snapshot changes.

  ## Examples

      iex> change_snapshot(snapshot)
      %Todo{...}

  """
  def change_snapshot(%Snapshot{} = snapshot, attrs \\ %{}) do
    snapshot = Repo.preload(snapshot, :tags)

    attrs =
      case Map.get(attrs, "tags") do
        nil -> attrs
        "" -> Map.delete(attrs, "tags")
        tags -> Map.put(attrs, "tags", String.split(tags, ",") |> Enum.map(&%Tag{name: &1}))
      end

    Snapshot.changeset(snapshot, attrs)
  end
end
