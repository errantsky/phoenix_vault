defmodule PhoenixVault.ArchiveFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PhoenixVault.Archive` context.
  """
  alias PhoenixVault.AccountsFixtures

  @doc """
  Generate a snapshot.
  """
  def snapshot_fixture(attrs \\ nil, user \\ nil) do
    user =
      if is_nil(user) do
        AccountsFixtures.user_fixture()
      else
        user
      end

    attrs =
      if is_nil(attrs) do
        %{
          "title" => "sample",
          "url" => "https://example.com"
        }
      end

    {:ok, snapshot} =
      attrs
      |> Enum.into(%{})
      |> PhoenixVault.Archive.create_snapshot(user)

    snapshot
  end
end
