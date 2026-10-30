defmodule CodeMantra.Repo do
  use Ecto.Repo,
    otp_app: :code_mantra,
    adapter: Ecto.Adapters.Postgres
end
