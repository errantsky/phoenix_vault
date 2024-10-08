defmodule PhoenixVaultWeb.SnapshotController do
  use PhoenixVaultWeb, :controller
  require Logger

  alias PhoenixVault.Accounts.User
  alias PhoenixVault.Archive
  alias PhoenixVault.Repo

  # todo: fetch the current_user
  # todo: archiver seems to not be working. The status seems to not be updated
  def create(conn, %{"snapshot" => snapshot_params}) do
    Logger.debug("SnapshotController.create conn: #{inspect(conn, pretty: true)}")

    # todo: auth
    current_user = Repo.get!(User, 1)

    case Archive.create_snapshot(snapshot_params, current_user) do
      {:ok, snapshot} ->
        conn
        |> put_status(:created)
        |> json(%{status: "successful", data: snapshot})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", errors: changeset.errors})
    end
  end
end
