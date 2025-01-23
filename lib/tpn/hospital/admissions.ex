defmodule Tpn.Admissions do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Admission
  alias Tpn.PatientMrn
  alias Tpn.Helpers.PaginationHelper

  def list_admissions(params, conn) do
    admissions =
      from(a in Admission)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(Admission, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in Admission)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, Admission)

    {:ok, {admissions, meta}}
  end

  def create_admission(attrs \\ %{}) do
    %Admission{}
    |> Admission.changeset(attrs)
    |> Repo.insert()
  end

  def get_admission!(id) do
    Repo.get!(Admission, id)
  end

  def get_mrn(patient_id, campus_id) do
    from(pm in PatientMrn,
      where: pm.patient_id == ^patient_id and pm.campus_id == ^campus_id
    )
    |> Repo.one()
  end

  def change_admission(admission) do
    Admission.changeset(admission, %{})
  end

  def update_admission(admission, params) do
    admission
    |> Admission.changeset(params)
    |> Repo.update()
  end

  def delete_admission(admission) do
    Repo.delete(admission)
  end
end
