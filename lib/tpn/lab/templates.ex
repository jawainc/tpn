defmodule Tpn.Templates do
  import Ecto.Query, warn: false

  alias Tpn.Repo
  alias Tpn.Template
  alias Tpn.TemplateView
  alias Tpn.Helpers.PaginationHelper

  def list_templates(params, conn) do
    templates =
      from(a in TemplateView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(TemplateView, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in TemplateView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, TemplateView)

    {:ok, {templates, meta}}
  end

  def templates_for_select do
    from(t in Template, order_by: [asc: :name])
    |> where([t], t.active == true)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_template(params) do
    IO.inspect(params)

    %Template{}
    |> Template.changeset(params)
    |> IO.inspect()
    |> Repo.insert()
  end

  def get_template!(id) do
    Repo.get!(Template, id)
  end

  def change_template(template) do
    Template.changeset(template, %{})
  end

  def delete_template(template) do
    Repo.delete(template)
  end

  def update_template(template, params) do
    template
    |> Template.changeset(params)
    |> Repo.update()
  end
end
