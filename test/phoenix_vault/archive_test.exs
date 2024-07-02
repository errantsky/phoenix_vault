defmodule PhoenixVault.ArchiveTest do
  use PhoenixVault.DataCase

  alias PhoenixVault.Archive

  describe "snapshots" do
    alias PhoenixVault.Schemas.Snapshot

    import PhoenixVault.ArchiveFixtures

    @invalid_attrs %{}

    test "list_snapshots/0 returns all snapshots" do
      snapshot = snapshot_fixture()
      assert Archive.list_snapshots() == [snapshot]
    end

    test "get_snapshot!/1 returns the snapshot with given id" do
      snapshot = snapshot_fixture()
      assert Archive.get_snapshot!(snapshot.id) == snapshot
    end

    test "create_snapshot/1 with valid data creates a snapshot" do
      valid_attrs = %{}

      assert {:ok, %Snapshot{} = snapshot} = Archive.create_snapshot(valid_attrs)
    end

    test "create_snapshot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Archive.create_snapshot(@invalid_attrs)
    end

    test "update_snapshot/2 with valid data updates the snapshot" do
      snapshot = snapshot_fixture()
      update_attrs = %{}

      assert {:ok, %Snapshot{} = snapshot} = Archive.update_snapshot(snapshot, update_attrs)
    end

    test "update_snapshot/2 with invalid data returns error changeset" do
      snapshot = snapshot_fixture()
      assert {:error, %Ecto.Changeset{}} = Archive.update_snapshot(snapshot, @invalid_attrs)
      assert snapshot == Archive.get_snapshot!(snapshot.id)
    end

    test "delete_snapshot/1 deletes the snapshot" do
      snapshot = snapshot_fixture()
      assert {:ok, %Snapshot{}} = Archive.delete_snapshot(snapshot)
      assert_raise Ecto.NoResultsError, fn -> Archive.get_snapshot!(snapshot.id) end
    end

    test "change_snapshot/1 returns a snapshot changeset" do
      snapshot = snapshot_fixture()
      assert %Ecto.Changeset{} = Archive.change_snapshot(snapshot)
    end
  end
end
