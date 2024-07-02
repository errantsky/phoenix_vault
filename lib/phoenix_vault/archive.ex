defmodule PhoenixVault.Archive do
  @moduledoc """
  The Archive context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Ecto.Changeset
  alias PhoenixVault.Archivers.ArchiverSupervisor
  alias PhoenixVault.Schemas.Tag
  alias PhoenixVault.Repo

  alias PhoenixVault.Schemas.Snapshot

  @doc """
  Returns the list of snapshots.

  ## Examples

      iex> list_snapshots()
      [%Snapshot{}, ...]

  """
  def list_snapshots(current_user) do
    Logger.debug("list_snapshots: current_user is #{inspect(current_user, pretty: true)}")

    query =
      from snapshot in Snapshot,
        where: snapshot.user_id == ^current_user.id

    Repo.all(query)
    |> Repo.preload(:tags)
  end

  @doc """
  Gets a single snapshot.

  Raises if the Snapshot does not exist.

  ## Examples

      iex> get_snapshot!(123)
      %Snapshot{}

  """
  def get_snapshot!(id, current_user) do
    if current_user == nil do
      Repo.get_by(Snapshot, id: id)
    else
      Repo.get_by(Snapshot, id: id, user_id: current_user.id)
    end
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
  def create_snapshot(attrs \\ %{}, current_user) do
    tags =
      case attrs["tags"] do
        nil ->
          []

        _ ->
          String.split(attrs["tags"], ",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(fn name -> %Tag{name: name} end)
      end

    Logger.debug("create_snapshot: #{inspect(attrs)}")
    Logger.debug("create_snapshot current_user: #{inspect(current_user, pretty: true)}")

    {:ok, snapshot} =
      Repo.insert(%Snapshot{
        url: attrs["url"],
        title: attrs["title"],
        user_id: current_user.id,
        tags: tags
      })

    ArchiverSupervisor.start_link(snapshot)

    {:ok, snapshot}
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

    Logger.debug("attrs is: #{inspect(attrs)}")

    snapshot = Repo.preload(snapshot, :tags)
    changeset = Snapshot.changeset(snapshot, attrs)

    Logger.debug("changeset is: #{inspect(changeset)}")

    case Repo.update(changeset) do
      {:ok, updated_snapshot} ->
        Logger.debug("updated_snapshot is: #{inspect(updated_snapshot)}")
        {:ok, updated_snapshot}

      {:error, changeset} ->
        Logger.debug("error is: #{inspect(changeset)}")
        {:error, changeset}
    end
  end

  def update_archiver_status(%Snapshot{} = snapshot, attrs) do
    Logger.debug("update_archiver_status: attrs is: #{inspect(attrs)}")

    snapshot = Repo.preload(snapshot, :tags)
    changeset = Snapshot.changeset(snapshot, attrs)

    Logger.debug("update_archiver_status: changeset is: #{inspect(changeset)}")

    case Repo.update(changeset) do
      {:ok, updated_snapshot} ->
        Logger.debug("update_archiver_status: updated_snapshot is: #{inspect(updated_snapshot)}")
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
    # Logger.debug("change_snapshot: #{inspect(attrs)}")
    snapshot = Repo.preload(snapshot, :tags)
    # if {:ok, tags} = Map.fetch(attrs, "tags") do
    #   tags = String.split(tags, ",")
    #   |> Enum.map(&%Tag{name: &1})
    #   attrs = Map.put(attrs, :tags, tags)
    # end

    Snapshot.changeset(snapshot, attrs)
  end
end
