defmodule PhoenixVault.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_vault,
    adapter: Ecto.Adapters.Postgres
end
