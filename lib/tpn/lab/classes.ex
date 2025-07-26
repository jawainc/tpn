defmodule Tpn.Classes do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Class
  alias Tpn.{Formulary, FormularyPatientType}
  alias Tpn.Helpers.PaginationHelper

  def classes() do
    Repo.all(Class, order_by: [asc: :name])
  end

  def list_classes(params) do
    classes =
      from(c in Class)
      |> PaginationHelper.build_query_params(Class, params, true)
      |> preload([:user])
      |> Repo.all()

    meta =
      from(c in Class)
      |> PaginationHelper.get_paging_meta(params, Class)

    {:ok, {classes, meta}}
  end

  def classes_for_select do
    from(c in Class, order_by: [asc: :name])
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def classes_with_formularies_for_patient_type(patient_type_id) do
    from(c in Class,
      join: f in Formulary,
      on: c.id == f.class_id,
      join: fpt in FormularyPatientType,
      on: f.id == fpt.formulary_id,
      where: fpt.patient_type_id == ^patient_type_id,
      distinct: c.id,
      order_by: [asc: c.name]
    )
    |> Repo.all()
  end

  def create_class(params) do
    %Class{}
    |> Class.changeset(params)
    |> Repo.insert()
  end

  def get_class!(id) do
    Repo.get!(Class, id)
  end

  def change_class(class) do
    Class.changeset(class, %{})
  end

  def update_class(class, params) do
    class
    |> Class.changeset(params)
    |> Repo.update()
  end

  def delete_class(class) do
    Repo.delete(class)
  end
end
