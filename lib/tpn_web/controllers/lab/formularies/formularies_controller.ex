defmodule TpnWeb.FormulariesController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.Lab.Ingredients
  alias Tpn.PatientTypes
  alias Tpn.Classes
  alias Tpn.Formularies
  alias Tpn.Formulary
  alias Tpn.Settings
  alias Tpn.Units
  alias Tpn.SolutionTypes
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  @calories_unit_type "formulary_calories_unit_type"
  @concentration_unit_type "formulary_concentration_unit_type"
  @ingredients_unit_type "formulary_ingredients_unit_type"
  @uom_unit_type "formulary_uom_unit_type"

  def index(conn, params) do
    with {:ok, {records, meta}} <- Formularies.list_formularies(params, conn) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: records)
    end
  end

  def new(conn, _params) do
    conn
    |> set_assigns()
    |> assign(:selected_patient_types, [])
    |> assign(:selected_ingredients, [])
    |> assign(:changeset, new_change())
    |> render(:new)
  end

  def new_change() do
    Formulary.changeset(%Formulary{})
  end

  def create(conn, %{"formulary" => formulary_params}) do
    params = Networks.params_assign_user(conn, formulary_params)

    case Formularies.create_formulary(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "",
            "success",
            "Created successfully."
          )
        )
        |> set_assigns()
        |> assign(:selected_patient_types, [])
        |> assign(:selected_ingredients, [])
        |> assign(:changeset, new_change())
        |> render(:new)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> set_assigns()
        |> assign(:selected_patient_types, [])
        |> assign(:selected_ingredients, [])
        |> assign(:changeset, changeset)
        |> render(:new)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Formularies.get_formulary_for_edit(id)
    changeset = Formularies.change_formulary(record)
    selected_patient_types = Enum.map(record.formulary_patient_types, & &1.patient_type_id)

    conn
    |> set_assigns()
    |> assign(:record, record)
    |> assign(:selected_patient_types, selected_patient_types)
    |> assign(:selected_ingredients, record.ingredients)
    |> assign(:changeset, changeset)
    |> render(:edit)
  end

  def update(conn, %{"id" => id, "formulary" => formulary_params}) do
    params = Networks.params_assign_user(conn, formulary_params)

    case Formularies.update_formulary(id, params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "",
            "success",
            "Updated successfully."
          )
        )
        |> send_resp(204, "")

      {:error, %Ecto.Changeset{} = changeset} ->
        record = Formularies.get_formulary_for_edit(id)
        selected_patient_types = Enum.map(record.formulary_patient_types, & &1.patient_type_id)

        conn
        |> set_assigns()
        |> assign(:record, record)
        |> assign(:selected_patient_types, selected_patient_types)
        |> assign(:selected_ingredients, record.ingredients)
        |> assign(:changeset, changeset)
        |> render(:edit)
    end
  end

  defp set_assigns(conn) do
    settings = get_settings()
    calories_units = Units.units_by_type_for_select(settings[@calories_unit_type])
    concentration_units = Units.units_by_type_for_select(settings[@concentration_unit_type])
    ingredients_units = Units.units_by_type_for_select(settings[@ingredients_unit_type])
    ingredients = Ingredients.ingredients_for_select_by_type(settings[@ingredients_unit_type])
    uom_units = Units.units_by_type_for_select(settings[@uom_unit_type])
    classes = Classes.classes_for_select()
    patient_types = PatientTypes.patient_types_for_select()
    solution_types = SolutionTypes.solution_types_for_select()

    conn
    |> assign(:currency, settings["currency"])
    |> assign(:calories_units, calories_units)
    |> assign(:concentration_units, concentration_units)
    |> assign(:ingredients_units, ingredients_units)
    |> assign(:ingredients, ingredients)
    |> assign(:uom_units, uom_units)
    |> assign(:classes, classes)
    |> assign(:patient_types, patient_types)
    |> assign(:solution_types, solution_types)
  end

  defp get_settings() do
    Settings.get_settings()
    |> Enum.map(&{&1.key, &1.value})
    |> Enum.into(%{})
  end
end
