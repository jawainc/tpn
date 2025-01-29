defmodule Tpn.Patients do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.{Patient, PatientView, Admission, AdmissionView}
  alias Tpn.Helpers.PaginationHelper

  def list_patients(params, _) do
    params =
      case params["filter_by"] do
        "First Name" -> Map.put(params, "filter_by", "first_name")
        "Last Name" -> Map.put(params, "filter_by", "last_name")
        "TPN I.D" -> Map.put(params, "filter_by", "tpn_id")
        "Location" -> Map.put(params, "filter_by", "city")
        "Email" -> Map.put(params, "filter_by", "email")
        "I.D" -> Map.put(params, "filter_by", "identity_no")
        "Phone" -> Map.put(params, "filter_by", "phone")
        _ -> params
      end

    patients =
      from(a in PatientView)
      |> PaginationHelper.build_query_params(PatientView, params, false)
      |> Repo.all()

    meta =
      from(a in PatientView)
      |> PaginationHelper.get_paging_meta(params, PatientView)

    {:ok, {patients, meta}}
  end

  def create_patient(attrs \\ %{}) do
    %Patient{}
    |> Patient.changeset(attrs)
    |> Repo.insert()
  end

  def get_patient!(id) do
    Repo.get!(PatientView, id)
  end

  def get_age!(id, opts \\ []) do
    query = from p in Patient, where: p.id == ^id, select: fragment("age(?)", p.dob)
    Repo.one!(query, opts)
  end

  def get_genders() do
    Patient.get_genders()
  end

  def get_admissions(id) do
    from(a in AdmissionView, where: a.patient_id == ^id, order_by: [desc: a.inserted_at])
    |> Repo.all()
  end

  def change_patient(patient) do
    Patient.changeset(patient, %{})
  end

  def update_patient(patient, params) do
    patient
    |> Patient.changeset(params)
    |> Repo.update()
  end

  def delete_patient(patient) do
    Repo.delete(patient)
  end
end
