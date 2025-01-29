defmodule TpnWeb.Helpers.PatientHelper do
  alias Ecto.UUID
  alias Tpn.Patients

  def calc_age(patient_id) do
    db_age = Patients.get_age!(patient_id)
    days = db_age.days
    months = db_age.months

    cond do
      months > 0 && months < 12 -> make_age(days, "Months")
      months >= 12 -> (months / 12) |> trunc() |> make_age("Years")
      true -> make_age(days, "Days")
    end
  end

  def generate_admission_number do
    DateTime.utc_now()
    |> DateTime.to_unix(:microsecond)
    |> Integer.to_string(36)
    |> String.slice(0, 15)
    |> String.upcase()
  end

  def generate_tpn_number do
    DateTime.utc_now()
    |> DateTime.to_unix(:microsecond)
    |> Integer.to_string(36)
    |> String.slice(0, 20)
    |> String.upcase()
  end

  def can_be_discharged?(%{is_admin: true}, _), do: true

  def can_be_discharged?(%{current_user: user}, patient_id) do
    cond do
      not is_nil(user.campus_id) ->
        patient_in_campus?(patient_id, user.campus_id)

      not is_nil(user.facility_id) ->
        patient_in_facility?(patient_id, user.facility_id)

      not is_nil(user.local_health_network_id) ->
        patient_in_lhn?(patient_id, user.local_health_network_id)

      true ->
        false
    end
  end

  defp patient_in_lhn?(patient_id, lhn_id) do
    with admission when not is_nil(admission) <-
           Tpn.Admissions.get_admission_by_lhn_id(patient_id, lhn_id) do
      true
    else
      _ -> false
    end
  end

  defp patient_in_facility?(patient_id, facility_id) do
    with admission when not is_nil(admission) <-
           Tpn.Admissions.get_admission_by_facility_id(patient_id, facility_id) do
      true
    else
      _ -> false
    end
  end

  defp patient_in_campus?(patient_id, campus_id) do
    IO.inspect("Patient ID: #{patient_id}")
    IO.inspect("Campus ID: #{campus_id}")

    with admission when not is_nil(admission) <-
           Tpn.Admissions.get_admission_by_campus_id(patient_id, campus_id) do
      true
    else
      _ -> false
    end
  end

  defp make_age(number, str) do
    "#{number} #{str}"
  end
end
