defmodule PhoenixVault.Archive do
  @moduledoc """
  The Archive context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias PhoenixVault.Tag
  alias PhoenixVault.Repo

  alias PhoenixVault.Snapshot

  @doc """
  Returns the list of snapshots.

  ## Examples

      iex> list_snapshots()
      [%Snapshot{}, ...]

  """
  def list_snapshots do
    Repo.all(Snapshot)
    |> Repo.preload(:tags)
  end

  @doc """
  Gets a single snapshot.

  Raises if the Snapshot does not exist.

  ## Examples

      iex> get_snapshot!(123)
      %Snapshot{}

  """
  def get_snapshot!(id) do
    Repo.get(Snapshot, id)
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
  def create_snapshot(attrs \\ %{}) do
    Repo.insert(%Snapshot{url: attrs[:url], title: attrs[:title]})
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
    tag_structs = Map.get(attrs, "tags")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn name -> %Tag{name: name} end)
    Logger.debug("tag_structs is: #{inspect(tag_structs)}")
    
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
