defmodule TpnWeb.Admission.Components.PatientComponent do
  @moduledoc """
  module for defining patient components
  """
  use Phoenix.Component
  import Phoenix.HTML
  import TpnWeb.CoreComponents

  @doc """
    defines the patient details component
  """
  attr :patient, :map, required: true
  attr :admission_number, :string, default: nil
  attr :admitted, :boolean, default: false
  attr :age, :string, required: false
  attr :can_be_discharged, :boolean, default: false

  def patient(assigns) do
    ~H"""
    <h1 class="mt-10 mb-2 font-semibold">Patient Details</h1>
    <div class="md:flex space-x-2 mb-10">
      <div class="bg-gray-300/10 dark:bg-gray-700/10 px-10 py-4 flex flex-col items-center min-w-[300px] border border-white/5 ">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 576 512"
          class="fill-gray-400 w-full max-w-[80px] "
        >
          <path d="M48 0C21.5 0 0 21.5 0 48V256H144c8.8 0 16 7.2 16 16s-7.2 16-16 16H0v64H144c8.8 0 16 7.2 16 16s-7.2 16-16 16H0v80c0 26.5 21.5 48 48 48H265.9c-6.3-10.2-9.9-22.2-9.9-35.1c0-46.9 25.8-87.8 64-109.2V271.8 48c0-26.5-21.5-48-48-48H48zM152 64h16c8.8 0 16 7.2 16 16v24h24c8.8 0 16 7.2 16 16v16c0 8.8-7.2 16-16 16H184v24c0 8.8-7.2 16-16 16H152c-8.8 0-16-7.2-16-16V152H112c-8.8 0-16-7.2-16-16V120c0-8.8 7.2-16 16-16h24V80c0-8.8 7.2-16 16-16zM512 272a80 80 0 1 0 -160 0 80 80 0 1 0 160 0zM288 477.1c0 19.3 15.6 34.9 34.9 34.9H541.1c19.3 0 34.9-15.6 34.9-34.9c0-51.4-41.7-93.1-93.1-93.1H381.1c-51.4 0-93.1 41.7-93.1 93.1z" />
        </svg>
        <div class="font-bold text-lg mt-5">{@patient.first_name} {@patient.last_name}</div>
        <div class="text-xs text-gray-500 dark:text-gray-600">{@patient.email}</div>
        <div class="mt-5 text-sm">
          {@patient.tpn_id}
        </div>
        <div class="font-semibold text-gray-500 dark:text-gray-600">TPN ID</div>
      </div>

      <div class=" flex flex-col divide-y divide-white/5 divide-gray-300 flex-grow bg-gray-700/10 border border-white/5">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-2 p-4">
          <div class="flex flex-col">
            <span class="font-semibold text-gray-600">Gender</span>
            <span class="text-sm">{@patient.gender}</span>
          </div>

          <div class="flex flex-col">
            <%= if !is_nil(@age) do %>
              <span class="font-semibold text-gray-600">Age</span>
              <span class="text-sm">{@age}</span>
            <% end %>
          </div>

          <div class="text-right">
            <.simple_badge
              state={@patient.is_admitted}
              label={
                if @patient.is_admitted do
                  "Admitteddddd"
                else
                  "Not-Admitted"
                end
              }
            />
            <%= if @patient.is_admitted do %>
              <button
                class="btn btn-primary btn-xs"
                hx-get={"/patients/#{@patient.id}/orders/new/"}
                hx-target="#main-contents"
                hx-indicator=".main-contents-loader"
              >
                New Order
              </button>
            <% end %>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-2 p-4">
          <div class="flex flex-col">
            <span class="font-semibold text-gray-600">Birthday</span>
            <span class="text-sm">{Calendar.strftime(@patient.dob, "%B %d, %Y")}</span>
          </div>
          <div class="flex flex-col">
            <span class="font-semibold text-gray-500 dark:text-gray-600">Identity No</span>
            <span class="text-sm">{@patient.identity_no}</span>
          </div>
          <div class="flex flex-col">
            <span class="font-semibold text-gray-500 dark:text-gray-600">Phone</span>
            <span class="text-sm">{@patient.phone}</span>
          </div>
        </div>
        <div class="grid grid-cols-1 gap-2 p-4">
          <div class="flex flex-col">
            <span class="font-semibold text-gray-500 dark:text-gray-600">Address</span>
            <p class="break-words ">
              <span class="block text-sm">{@patient.address_1}</span>
              <span class="block text-sm">{@patient.address_2}</span>
              <span class="block text-sm">
                {@patient.city} {@patient.state} {@patient.zip} {@patient.country}
              </span>
            </p>
          </div>
        </div>
      </div>
      <div class="bg-gray-300/10 relative box-border dark:bg-gray-700/10 py-4 min-w-[300px] border border-gray-300 dark:border-slate-800">
        <h3 class="font-semibold px-6 text-gray-500 dark:text-gray-600">Notes</h3>
        <div class="px-6 py-2 break-words max-w-[280px] text-sm">
          {raw(format_lines(@patient.notes))}
        </div>
      </div>
    </div>
    """
  end

  defp format_lines(nil), do: ""

  defp format_lines(string) do
    String.replace(string, "\n", "<br>")
  end
end
