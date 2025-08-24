defmodule TpnWeb.Templates.TemplateProductsComponent do
  @moduledoc """
  module for defining template products
  """
  use Phoenix.Component
  import TpnWeb.IconComponents
  import TpnWeb.CoreComponents

  @doc """
    defines the template products component
  """

  attr :template_id, :integer, required: true

  def template_products(assigns) do
    ~H"""
    <section class="w-full rounded-lg border mt-16">
      <header class="flex items-center justify-between border-b px-4 py-3 font-semibold bg-card text-card-foreground">
        <span>Products</span>
        <button
          class="btn-sm-outline btn-xs"
          hx-get={"/template_products/#{@template_id}/new"}
          hx-target="#template_table_form_modal_contents"
          hx-indicator="#template_table_modal_loader"
          hx-on:click="document.getElementById('template_table_modal_contents').showModal()"
          type="button"
          aria-label="Add Product"
        >
          <.icon_plus />
          <span>Add Product</span>
        </button>
      </header>
      <div
        hx-get={"/template_products/#{@template_id}/list"}
        hx-trigger="load, reloadProductsTable from:body"
        hx-indicator="#products_loader"
        hx-target="#products_container"
        class="flex flex-col items-center justify-center"
      >
        <.loader id="products_loader" class="text-muted-foreground my-24" />
        <div id="products_container" class="hide-on-htmx-request"></div>
      </div>
    </section>
    """
  end
end
