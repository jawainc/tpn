defmodule TPN.Orders do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Order

  def list_orders(params, _) do
    orders =
      from(o in Order)
      |> where([o], o.admission_id == ^params["admission_id"])
      |> Repo.all()

    {:ok, orders}
  end

  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end
end
