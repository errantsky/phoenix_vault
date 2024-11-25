defmodule PhoenixVault.ArchiveTest do
  use PhoenixVault.DataCase

  alias PhoenixVault.Archive

  describe "snapshots" do
    alias PhoenixVault.Schemas.Snapshot

    import PhoenixVault.ArchiveFixtures
    import PhoenixVault.AccountsFixtures

    @invalid_attrs %{"title" => nil}

    setup do
      {:ok, user: user_fixture()}
    end

    test "list_snapshots/0 returns all snapshots", %{user: user} do
      snapshot = snapshot_fixture(nil, user)
      assert Archive.list_snapshots(user) == [snapshot]
    end

    test "get_snapshot!/1 returns the snapshot with given id", %{user: user} do
      snapshot = snapshot_fixture(nil, user)
      assert Archive.get_snapshot!(snapshot.id, user) == snapshot
    end

    test "create_snapshot/1 with valid data creates a snapshot", %{user: user} do
      valid_attrs = %{"title" => "sample", "url" => "https://example.com"}

      assert {:ok, %Snapshot{}} = Archive.create_snapshot(valid_attrs, user)
    end

    test "create_snapshot/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Archive.create_snapshot(@invalid_attrs, user)
    end

    test "update_snapshot/2 with valid data updates the snapshot", %{user: user} do
      snapshot = snapshot_fixture(nil, user)
      update_attrs = %{"title" => "new title"}

      assert {:ok, %Snapshot{title: "new title"}} =
               Archive.update_snapshot(snapshot, update_attrs)
    end

    test "update_snapshot/2 with invalid data returns error changeset", %{user: user} do
      snapshot = snapshot_fixture(nil, user)
      assert {:error, %Ecto.Changeset{}} = Archive.update_snapshot(snapshot, @invalid_attrs)
      assert snapshot == Archive.get_snapshot!(snapshot.id, user)
    end

    test "delete_snapshot/1 deletes the snapshot", %{user: user} do
      snapshot = snapshot_fixture()
      assert {:ok, %Snapshot{}} = Archive.delete_snapshot(snapshot)
      assert_raise Ecto.NoResultsError, fn -> Archive.get_snapshot!(snapshot.id, user) end
    end

    test "change_snapshot/1 returns a snapshot changeset" do
      snapshot = snapshot_fixture()
      assert %Ecto.Changeset{} = Archive.change_snapshot(snapshot)
    end
  end
end
