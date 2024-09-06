defmodule PhoenixVault.Archivers.ArchiverConfig do
  @moduledoc """
  Shared configuration for archiver processes.
  """
  require Logger

  def snapshot_dir(id) do
    path = Path.expand(Integer.to_string(id), Application.get_env(:phoenix_vault, :archive_dir))
    Logger.debug("snapshot_dir is: #{path}")
    path
  end
end
