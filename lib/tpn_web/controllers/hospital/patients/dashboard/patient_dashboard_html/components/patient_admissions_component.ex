defmodule TpnWeb.Hospital.Components.PatientAdmissionsComponent do
  use Phoenix.Component
  import Phoenix.HTML
  import TpnWeb.CoreComponents

  @doc """
    defines the patient admissions component
  """
  attr :admissions, :list, required: true
  attr :patient_id, :integer, required: true

  def patient_admissions(assigns) do
    ~H"""
    <div
      hx-get={"/patients/#{@patient_id}/admissions"}
      hx-trigger="reloadPatientAdmissionTable"
      hx-indicator="#admissions_loader"
      class="mt-10"
    >
      <span id="admissions_loader" class="loading loading-spinner loading-md htmx-indicator"></span>
      <h1 class="font-semibold">Admissions</h1>
      <%= if Enum.empty?(@admissions) do %>
        <.no_records />
      <% else %>
        <div class="mt-5">
          <%= for admission <- @admissions do %>
            <li class="relative flex items-center space-x-4 py-4">
              <div class="">
                <div class="flex items-center gap-x-3">
                  <%= if !admission.discharged do %>
                    <div class="flex-none rounded-full bg-green-100/10 p-1 text-green-500">
                      <div class="size-2 rounded-full bg-current"></div>
                    </div>
                  <% else %>
                    <div class="flex-none rounded-full bg-gray-100/10 p-1 text-gray-500">
                      <div class="size-2 rounded-full bg-current"></div>
                    </div>
                  <% end %>
                  <div>
                    <p class="truncate">Admission No: {admission.admission_no}</p>
                  </div>
                </div>
                <div class="mt-3 flex items-center gap-x-2.5 text-xs/5 text-gray-400">
                  <p class="whitespace-nowrap">M.R.N: {admission.mrn}</p>
                </div>
              </div>
              <div class="flex flex-col space-y-2 pl-20 text-xs/5 text-gray-400">
                <p class="whitespace-nowrap">Age: {admission.age}</p>
                <p class="whitespace-nowrap">Type: {admission.patient_type}</p>
              </div>
              <div class="min-w-0 flex-auto flex flex-col space-y-2 pl-20 text-xs/5 text-gray-400">
                <p class="whitespace-nowrap">
                  Weight: {admission.patient_weight}{admission.weight_unit}
                </p>
                <p class="whitespace-nowrap">
                  Height {admission.patient_height}{admission.height_unit}
                </p>
              </div>
              <div class="min-w-0 flex-auto flex flex-col space-y-2 pl-20 text-xs/5 text-gray-400">
                <p class="whitespace-nowrap">L.H.N: {admission.local_health_network}</p>
                <p class="whitespace-nowrap">Facility {admission.facility}</p>
                <p class="whitespace-nowrap">Campus {admission.campus}</p>
              </div>
              <div class="min-w-0 flex-auto flex flex-col space-y-2 pl-20 text-xs/5 text-gray-400">
                <p class="whitespace-nowrap">Notes:</p>
                <p class="whitespace-nowrap">{raw(format_lines(admission.notes))}</p>
              </div>
              <div class="flex-none rounded-full bg-gray-400/10 px-2 py-1 text-xs font-medium text-gray-400 ring-1 ring-inset ring-gray-400/20 cursor-pointer">
                Preview
              </div>
            </li>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def format_lines(nil), do: ""

  def format_lines(string) do
    String.replace(string, "\n", "<br>")
  end
end
