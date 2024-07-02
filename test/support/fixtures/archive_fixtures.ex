defmodule PhoenixVault.ArchiveFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PhoenixVault.Archive` context.
  """

  @doc """
  Generate a snapshot.
  """
  def snapshot_fixture(attrs \\ %{title: "test", url: "https://hexdocs.pm/elixir"}) do
    {:ok, snapshot} =
      attrs
      |> Enum.into(%{})
      |> PhoenixVault.Archive.create_snapshot()

    snapshot
  end
end
