defmodule PhoenixVault.Archivers.ArchiverConfig do
  @moduledoc """
  Shared configuration for archiver processes.
  """
  require Logger

  alias PhoenixVault.Schemas.Snapshot

  def snapshot_dir(%Snapshot{id: id}) do
    path = Path.expand(Integer.to_string(id), Application.get_env(:phoenix_vault, :archive_dir))
    Logger.debug("snapshot_dir is: #{path}")
    path
  end
end
