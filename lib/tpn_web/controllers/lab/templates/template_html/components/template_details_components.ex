defmodule TpnWeb.Templates.TemplateDetailsComponent do
  @moduledoc """
  module for defining template details
  """
  use Phoenix.Component
  import TpnWeb.CoreComponents

  @doc """
    defines the template details component
  """
  attr :template, :map, required: true

  def template_details(assigns) do
    ~H"""
    <div class="bg-gray-300/10 dark:bg-gray-700/10 px-10 py-4 flex flex-col border border-white/5 rounded-md mt-10">
      <div class="flex space-x-3 items-center">
        <div class="font-semibold">{@template.name}</div>
        <.simple_badge
          state={@template.active}
          label={
            if(@template.active) do
              "Active"
            else
              "Inactive"
            end
          }
          type="outline"
        />
      </div>

      <div class="grid grid-cols-4 gap-5 mt-10">
        <div>
          <div class="text-sm text-gray-500 dark:text-gray-600">Patient Type</div>
          <div class="font-semibold text-lg">{@template.patient_type_name}</div>
        </div>
        <div>
          <div class="text-sm text-gray-500 dark:text-gray-600">Bag Over Fill Volume</div>
          <div class="font-semibold text-lg">{@template.bag_over_fill_volume}</div>
        </div>
        <div>
          <div class="text-sm text-gray-500 dark:text-gray-600">Lipid Over Fill Volume</div>
          <div class="font-semibold text-lg">{@template.lipid_over_fill_volume}</div>
        </div>
        <div>
          <div class="text-sm text-gray-500 dark:text-gray-600">Fluids</div>
          <div class="font-semibold text-lg">{@template.fluids}/{@template.fluid_unit}</div>
        </div>
        <div>
          <div class="text-sm text-gray-500 dark:text-gray-600">Pre Mixed Standard</div>
          <div class="font-semibold text-lg">
            <.simple_badge
              state={@template.pre_mixed_standard}
              label={
                if(@template.pre_mixed_standard) do
                  "Active"
                else
                  "Inactive"
                end
              }
              type="outline"
            />
          </div>
        </div>
        <div>
          <div class="text-sm text-gray-500 dark:text-gray-600">Additional Substances Allowed</div>
          <div class="font-semibold text-lg">
            <.simple_badge
              state={@template.additional_substances_allowed}
              label={
                if(@template.additional_substances_allowed) do
                  "Active"
                else
                  "Inactive"
                end
              }
              type="outline"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
