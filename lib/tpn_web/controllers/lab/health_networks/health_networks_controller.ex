defmodule TpnWeb.HealthNetworks.HealthNetworksController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false
  alias Tpn.Repo

  def networks(conn, params) do
    network = Map.values(params) |> List.first()
    network_data(conn, network)
  end

  def hospitals(conn, params) do
    network = Map.values(params) |> List.first()
    hospital_data(conn, network)
  end

  def wards(conn, params) do
    ward_data(conn, params)
  end

  def rooms(conn, %{"ward_id" => id}) do
    room_data =
      Tpn.Hospital.Room
      |> where([f], f.ward_id == ^id)
      |> order_by(asc: :name)
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})

    render(conn, :rooms, rooms: room_data)
  end

  def beds(conn, %{"room_id" => id}) do
    bed_data =
      Tpn.Hospital.Bed
      |> where([f], f.room_id == ^id)
      |> order_by(asc: :name)
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})

    render(conn, :beds, beds: bed_data)
  end

  def mrn(conn, %{"patient_id" => patient_id, "campus_id" => campus_id}) do
    mrn_data =
      Tpn.PatientMrn
      |> where([m], m.patient_id == ^patient_id)
      |> where([m], m.campus_id == ^campus_id)
      |> Repo.one()

    IO.inspect(mrn_data)

    render(conn, :mrn, mrn: mrn_data)
  end

  defp ward_data(conn, %{"id" => id, "type" => "lhn"}) do
    ward_data =
      Tpn.Hospital.Ward
      |> where([w], w.local_health_network_id == ^id)
      |> order_by(asc: :name)
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})

    render(conn, :wards, wards: ward_data)
  end

  defp ward_data(conn, %{"id" => id, "type" => "facility"}) do
    ward_data =
      Tpn.Hospital.Ward
      |> where([w], w.facility_id == ^id)
      |> order_by(asc: :name)
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})

    render(conn, :wards, wards: ward_data)
  end

  defp ward_data(conn, %{"id" => id, "type" => "campus"}) do
    ward_data =
      Tpn.Hospital.Ward
      |> where([w], w.campus_id == ^id)
      |> order_by(asc: :name)
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})

    render(conn, :wards, wards: ward_data)
  end

  defp hospital_data(conn, %{"ward_id" => id}) do
    room_data =
      Tpn.Hospital.Room
      |> where([f], f.ward_id == ^id)
      |> order_by(asc: :name)
      |> Repo.all()
      |> Enum.map(&{&1.name, &1.id})

    render(conn, :rooms, rooms: room_data)
  end

  defp network_data(conn, %{"local_health_network_id" => id}) do
    facilities_data =
      case id do
        "" ->
          []

        _ ->
          Tpn.Accounts.Networks.Facility
          |> where([f], f.local_health_network_id == ^id)
          |> order_by(asc: :name)
          |> Repo.all()
          |> Enum.map(&{&1.name, &1.id})
      end

    render(conn, :facilities, facilities: facilities_data)
  end

  defp network_data(conn, %{"facility_id" => id}) do
    campuses_data =
      case id do
        "" ->
          []

        _ ->
          Tpn.Accounts.Networks.Campus
          |> where([c], c.facility_id == ^id)
          |> order_by(asc: :name)
          |> Repo.all()
          |> Enum.map(&{&1.name, &1.id})
      end

    render(conn, :campuses, campuses: campuses_data)
  end
end
