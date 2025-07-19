defmodule TpnWeb.Admission.Components.AdmissionsRecordsComponent do
  use Phoenix.Component
  import Phoenix.HTML
  import TpnWeb.CoreComponents

  @doc """
  Renders the admissions records component
  """
  attr :admissions, :list, required: true
  def admission_records(assigns) do
    ~H"""
    <%= for admission <- @admissions do %>
    <li class="relative flex items-start space-x-4 py-4">
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
            <svg viewBox="0 0 2 2" class="size-0.5 flex-none fill-gray-300">
                <circle cx="1" cy="1" r="1" />
            </svg>
            <p class="whitespace-nowrap">Age: {admission.age}</p>
        </div>
    </div>
    <div class="flex flex-col space-y-2 pl-20 text-xs/5 text-gray-400">
        <p :if={admission.discharged} class="whitespace-nowrap">
            Discharged Date: {format_date(admission.discharged_at)}
        </p>
        <p class="whitespace-nowrap">
            Admission Date: {format_date(admission.inserted_at)}
        </p>
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
        <p class="whitespace-nowrap">Facility: {admission.facility}</p>
        <p class="whitespace-nowrap">Campus: {admission.campus}</p>
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
    """
  end

  def format_lines(nil), do: ""

  def format_lines(string) do
    String.replace(string, "\n", "<br>")
  end

  def format_date(nil), do: ""

  def format_date(date) do
    {:ok, formatted_date} = Timex.format(date, "{M}/{D}/{YYYY} {h12}:{m} {AM}")
    formatted_date
  end
end
