defmodule TpnWeb.Hospital.Components.PatientAdmissionsComponent do
  use Phoenix.Component
  import Phoenix.HTML
  import TpnWeb.CoreComponents

  @doc """
    defines the patient admissions component
  """
  attr :admissions, :list, required: true

  def patient_admissions(assigns) do
    ~H"""
    <div class="mt-10">
      <h1 class="font-semibold">Admissions</h1>
      <%= if Enum.empty?(@admissions) do %>
        <.no_records />
      <% else %>
        <div class="mt-5">
          <%= for admission <- @admissions do %>
            <div class="bg-gray-300/10 dark:bg-gray-700/10 p-4 mb-4 border border-white/5">
              <div class="flex justify-between">
                <div class="font-semibold text-lg">
                  <%= admission.admission_no %>
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-600">
                  <%= admission.admitted_at %>
                </div>
              </div>
              <div class="mt-2">
                <div class="text-sm text-gray-500 dark:text-gray-600">
                  <%= admission.ward.name %>
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-600">
                  <%= admission.room.name %>
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-600">
                  <%= admission.bed.name %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
