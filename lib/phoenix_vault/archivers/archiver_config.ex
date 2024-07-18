defmodule PhoenixVault.Archivers.ArchiverConfig do
  @moduledoc """
  Shared configuration for archiver processes.
  """
  require Logger

  alias PhoenixVault.Schemas.Snapshot

  def snapshot_dir(%Snapshot{id: id}) do
    path = Path.expand(Path.join(Application.get_env(:phoenix_vault, :archive_dir), Integer.to_string(id)))
    Logger.debug("snapshot_dir is: #{path}")
    path
  end
end
