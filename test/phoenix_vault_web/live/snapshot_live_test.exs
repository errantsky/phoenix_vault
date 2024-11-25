defmodule PhoenixVaultWeb.SnapshotLiveTest do
  use PhoenixVaultWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhoenixVault.ArchiveFixtures

  @create_attrs %{title: "sample title", url: "http://example.com"}
  @update_attrs %{title: "new title"}

  defp create_snapshot(%{user: user}) do
    snapshot = snapshot_fixture(nil, user)
    %{snapshot: snapshot}
  end

  defp register_and_login(%{conn: conn}) do
    %{conn: _conn, user: _user} = register_and_log_in_user(%{conn: conn})
  end

  describe "Index" do
    setup [:register_and_login, :create_snapshot]

    test "lists all snapshots", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/snapshots")

      assert html =~ "Listing Snapshots"
    end

    test "saves new snapshot", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/snapshots")

      assert index_live |> element("a", "New Snapshot") |> render_click() =~
               "New Snapshot"

      assert_patch(index_live, ~p"/snapshots/new")

      assert index_live
             |> form("#snapshot-form", snapshot: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/snapshots")

      html = render(index_live)
      assert html =~ "Snapshot created successfully"
    end

    test "updates snapshot in listing", %{conn: conn, snapshot: snapshot} do
      {:ok, index_live, _html} = live(conn, ~p"/snapshots")

      assert index_live |> element("#snapshots-#{snapshot.id} a", "Edit") |> render_click() =~
               "Edit Snapshot"

      assert_patch(index_live, ~p"/snapshots/#{snapshot}/edit")

      assert index_live
             |> form("#snapshot-form", snapshot: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/snapshots")

      html = render(index_live)
      assert html =~ "Snapshot updated successfully"
    end

    test "deletes snapshot in listing", %{conn: conn, snapshot: snapshot} do
      {:ok, index_live, _html} = live(conn, ~p"/snapshots")

      assert index_live |> element("#snapshots-#{snapshot.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#snapshots-#{snapshot.id}")
    end
  end

  describe "Show" do
    setup [:register_and_login, :create_snapshot]

    test "displays snapshot", %{conn: conn, snapshot: snapshot} do
      {:ok, _show_live, html} = live(conn, ~p"/snapshots/#{snapshot}")

      assert html =~ "Show Snapshot"
    end

    test "updates snapshot within modal", %{conn: conn, snapshot: snapshot} do
      {:ok, show_live, _html} = live(conn, ~p"/snapshots/#{snapshot}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Snapshot"

      assert_patch(show_live, ~p"/snapshots/#{snapshot}/show/edit")

      assert show_live
             |> form("#snapshot-form", snapshot: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/snapshots/#{snapshot}")

      html = render(show_live)
      assert html =~ "Snapshot updated successfully"
    end
  end
end
