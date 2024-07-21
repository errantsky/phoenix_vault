defmodule PhoenixVault.Archivers.ArchiverConfig do
  @moduledoc """
  Shared configuration for archiver processes.
  """
  require Logger

  alias PhoenixVault.Schemas.Snapshot

  def snapshot_dir(%Snapshot{id: id}) do
    archive_dir = Application.get_env(:phoenix_vault, :archive_dir)
    unless archive_dir do
      raise "Archive directory not configured in :phoenix_vault application"
    end
    path = Path.expand(archive_dir, Integer.to_string(id))
    Logger.debug("snapshot_dir is: #{path}")
    path
  end
end
