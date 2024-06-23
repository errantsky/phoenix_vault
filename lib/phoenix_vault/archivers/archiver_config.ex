defmodule PhoenixVault.Archivers.ArchiverConfig do
  @moduledoc """
  Shared configuration for archiver processes.
  """

  alias PhoenixVault.Snapshot

  @base_dir "priv/archive"

  def snapshot_dir(%Snapshot{id: id}) do
    Path.expand(Path.join(@base_dir, Integer.to_string(id)))
  end
end
