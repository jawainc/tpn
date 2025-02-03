defmodule TpnWeb.Templates.TemplateProductsComponent do
  @moduledoc """
  module for defining template products
  """
  use Phoenix.Component

  @doc """
    defines the template products component
  """

  attr :template_id, :integer, required: true

  def template_products(assigns) do
    ~H"""
    <div class="mt-20">
      <div class="flex justify-between">
        <div class="font-semibold">Products</div>
        <button
          hx-get={"/template_products/#{@template_id}/new"}
          hx-target="#table_modal_contents"
          hx-on:click="table_modal.showModal()"
          class="btn btn-primary btn-sm"
        >
          Add Product
        </button>
      </div>

      <div
        hx-get={"/template_products/#{@template_id}/list"}
        hx-trigger="load, reloadProductsTable from:body"
        hx-indicator="#products_loader"
        hx-target="#products_container"
        class="mt-10"
      >
        <span id="products_loader" class="loading loading-spinner loading-md htmx-indicator"></span>
        <div id="products_container"></div>
      </div>
    </div>
    """
  end
end
