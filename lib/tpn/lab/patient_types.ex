defmodule Tpn.PatientTypes do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.PatientType
  alias Tpn.Helpers.PaginationHelper

  def patient_types() do
    Repo.all(PatientType, order_by: [asc: :name])
  end

  def list_patient_types(params) do
    patient_types =
      from(pt in PatientType)
      |> PaginationHelper.build_query_params(PatientType, params, true)
      |> preload([:user])
      |> Repo.all()

    meta =
      from(pt in PatientType)
      |> PaginationHelper.get_paging_meta(params, PatientType)

    {:ok, {patient_types, meta}}
  end

  def patient_types_for_select do
    PatientType
    |> order_by(asc: :name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_patient_type(params) do
    %PatientType{}
    |> PatientType.changeset(params)
    |> Repo.insert()
  end

  def get_patient_type!(id) do
    Repo.get!(PatientType, id)
  end

  def change_patient_type(patient_type) do
    PatientType.changeset(patient_type, %{})
  end

  def update_patient_type(patient_type, params) do
    patient_type
    |> PatientType.changeset(params)
    |> Repo.update()
  end

  def delete_patient_type(patient_type) do
    Repo.delete(patient_type)
  end
end
