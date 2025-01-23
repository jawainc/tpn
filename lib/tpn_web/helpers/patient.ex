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

  defp make_age(number, str) do
    "#{number} #{str}"
  end
end
