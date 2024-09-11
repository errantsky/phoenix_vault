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

  def get_root_domain(url) do
    %URI{host: host} = URI.parse(url)
    host_parts = String.split(host, ".")

    case Enum.count(host_parts) do
      # If there are only two parts, return as is (e.g., example.com)
      2 ->
        host

      # If there are more than two parts, return the last two parts (e.g., sub.example.com -> example.com)
      count when count > 2 ->
        Enum.join(Enum.take(host_parts, -2), ".")
    end
  end
end
