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

  def list_template_products_by_template_id(template_id) do
    from(a in TemplateProductView,
      where: a.template_id == ^template_id,
      order_by: [asc: :position]
    )
    |> Repo.all()
  end

  def create_template_product(params) do
    max_position_query =
      from(t in TemplateProduct,
        select: max(t.position)
      )

    current_max_position = Repo.one(max_position_query) || -1
    new_position = current_max_position + 1

    params = Map.put(params, "position", new_position)

    %TemplateProduct{}
    |> TemplateProduct.changeset(params)
    |> Repo.insert()
  end

  def get_template_products_by_template_id(template_id) do
    from(a in TemplateProductView, where: a.template_id == ^template_id)
    |> Repo.all()
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

  def sort_template_products(products) when is_list(products) do
    Repo.transaction(fn ->
      Enum.each(products, fn data ->
        [product_id, position] = String.split(data, ",")

        from(tp in TemplateProduct,
          where: tp.id == ^product_id
        )
        |> Repo.update_all(
          set: [
            position: position,
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          ]
        )
      end)
    end)
  end
end
