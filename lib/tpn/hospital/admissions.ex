defmodule Tpn.Admissions do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Tpn.Repo
  alias Tpn.{Admission, AdmissionView}
  alias Tpn.PatientMrn
  alias Tpn.Helpers.PaginationHelper

  def list_admissions(params) do
    admissions =
      from(a in AdmissionView)
      |> PaginationHelper.build_query_params(AdmissionView, params, false)
      |> Repo.all()

    {:ok, admissions}
  end

  def get_admission_by_lhn_id(patient_id, lhn_id) do
    from(a in Admission)
    |> where([a], a.patient_id == ^patient_id)
    |> where([a], a.local_health_network_id == ^lhn_id)
    |> where([a], a.discharged == false)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.one()
  end

  def get_admission_by_facility_id(patient_id, facility_id) do
    from(a in Admission)
    |> where([a], a.patient_id == ^patient_id)
    |> where([a], a.facility_id == ^facility_id)
    |> where([a], a.discharged == false)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.one()
  end

  def get_admission_by_campus_id(patient_id, campus_id) do
    from(a in Admission)
    |> where([a], a.patient_id == ^patient_id)
    |> where([a], a.campus_id == ^campus_id)
    |> where([a], a.discharged == false)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.one()
  end

  def create_admission(attrs \\ %{}) do
    multi =
      Multi.new()
      |> Multi.insert(:admission, %Admission{} |> Admission.changeset(attrs))
      |> Multi.run(:patient_mrn, fn _repo, %{admission: admission} ->
        case Map.has_key?(attrs, "mrn") do
          true ->
            {:ok,
             %PatientMrn{}
             |> PatientMrn.changeset(%{
               patient_id: admission.patient_id,
               campus_id: admission.campus_id,
               facility_id: admission.facility_id,
               local_health_network_id: admission.local_health_network_id,
               user_id: admission.user_id,
               mrn: attrs["mrn"]
             })}

          false ->
            {:ok, nil}
        end
      end)

    case Repo.transaction(multi) do
      {:ok, %{admission: admission} = _multi_result} ->
        {:ok, admission}

      {:error, changeset} ->
        {:error, changeset}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def get_admission!(id) do
    Repo.get!(Admission, id)
  end

  def discharge_admission(patient_id) do
    from(a in Admission,
      where: a.patient_id == ^patient_id and a.discharged == false,
      update: [set: [discharged: true, discharged_at: fragment("NOW()")]]
    )
    |> Repo.update_all([])
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
