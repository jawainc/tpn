defmodule Tpn.Orders do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Order

  def list_orders_by_admission_id(admission_id) do
    orders =
      from(o in Order)
      |> where([o], o.admission_id == ^admission_id)
      |> Repo.all()

    orders
  end

  def list_orders_by_patient_id(patient_id) do
    orders =
      from(o in Order)
      |> where([o], o.patient_id == ^patient_id)
      |> Repo.all()

    orders
  end

  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end
end
