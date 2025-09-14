defmodule Tpn.Admissions do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Tpn.Repo
  alias Tpn.{Admission, AdmissionView}
  alias Tpn.PatientMrn

  def list_admissions(%{"patient_id" => patient_id} = _params) do
    admissions =
      from(a in AdmissionView)
      |> where([a], a.patient_id == ^patient_id)
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()

    {:ok, admissions}
  end

  def list_admissions_for_user(_, _, campus_id) when not is_nil(campus_id) do
    admissions =
      from(a in AdmissionView)
      |> where([a], a.campus_id == ^campus_id)
      |> where([a], a.discharged == false)
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()

    {:ok, admissions}
  end

  def list_admissions_for_user(_, facility_id, _) when not is_nil(facility_id) do
    admissions =
      from(a in AdmissionView)
      |> where([a], a.facility_id == ^facility_id)
      |> where([a], a.discharged == false)
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()

    {:ok, admissions}
  end

  def list_admissions_for_user(lhn_id, _, _) when not is_nil(lhn_id) do
    admissions =
      from(a in AdmissionView)
      |> where([a], a.local_health_network_id == ^lhn_id)
      |> where([a], a.discharged == false)
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()

    {:ok, admissions}
  end

  def list_admissions_for_user(_, _, _) do
    admissions =
      from(a in AdmissionView)
      |> where([a], a.discharged == false)
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()

    {:ok, admissions}
  end

  def get_admission_by_lhn_id(patient_id, lhn_id) do
    from(a in Admission)
    |> where([a], a.patient_id == ^patient_id)
    |> where([a], a.local_health_network_id == ^lhn_id)
    |> where([a], a.discharged == false)
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_admission_by_facility_id(patient_id, facility_id) do
    from(a in Admission)
    |> where([a], a.patient_id == ^patient_id)
    |> where([a], a.facility_id == ^facility_id)
    |> where([a], a.discharged == false)
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_admission_by_campus_id(patient_id, campus_id) do
    from(a in Admission)
    |> where([a], a.patient_id == ^patient_id)
    |> where([a], a.campus_id == ^campus_id)
    |> where([a], a.discharged == false)
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_admission_view_by_patient_id(patient_id) do
    from(a in AdmissionView)
    |> where([a], a.patient_id == ^patient_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def create_admission(attrs \\ %{}) do
    multi =
      Multi.new()
      |> Multi.insert(:admission, %Admission{} |> Admission.changeset(attrs))
      |> Multi.merge(fn %{admission: admission} ->
        case Map.has_key?(attrs, "mrn") do
          false ->
            Multi.new()

          _ ->
            Multi.new()
            |> Multi.insert(
              :patient_mrn,
              %PatientMrn{}
              |> PatientMrn.changeset(%{
                patient_id: admission.patient_id,
                campus_id: admission.campus_id,
                facility_id: admission.facility_id,
                local_health_network_id: admission.local_health_network_id,
                user_id: admission.user_id,
                mrn: attrs["mrn"]
              })
            )
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

  def get_admission_view(id) do
    Repo.get!(AdmissionView, id)
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
