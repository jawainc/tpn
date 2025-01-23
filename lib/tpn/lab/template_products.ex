defmodule Tpn.TemplateProducts do
  import Ecto.Query, warn: false

  alias Tpn.Repo
  alias Tpn.TemplateProduct
  alias Tpn.TemplateProductView
  alias Tpn.Helpers.PaginationHelper

  def list_template_products(params, conn) do
    template_products =
      from(a in TemplateProductView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(
        TemplateProductView,
        params,
        !conn.assigns[:is_admin]
      )
      |> Repo.all()

    meta =
      from(a in TemplateProductView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, TemplateProductView)

    {:ok, {template_products, meta}}
  end

  def create_template_product(params) do
    %TemplateProduct{}
    |> TemplateProduct.changeset(params)
    |> Repo.insert()
  end

  def get_template_product!(id) do
    Repo.get!(TemplateProduct, id)
  end

  def change_template_product(template_product) do
    TemplateProduct.changeset(template_product, %{})
  end

  def delete_template_product(template_product) do
    Repo.delete(template_product)
  end

  def update_template_product(template_product, params) do
    template_product
    |> TemplateProduct.changeset(params)
    |> Repo.update()
  end
end
