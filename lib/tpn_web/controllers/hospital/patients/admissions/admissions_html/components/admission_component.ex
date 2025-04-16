defmodule TpnWeb.Admission.Components.AdmissionComponent do
  @moduledoc """
  module for defining patient components
  """
  use Phoenix.Component
  import Phoenix.HTML
  import TpnWeb.CoreComponents

  @doc """
    defines the patient details component
  """
  attr :admission, :map, required: true

  def admission(assigns) do
    ~H"""
    <h1 class="mt-10 mb-2 font-semibold">Admission Details</h1>
    """
  end

  defp format_lines(nil), do: ""

  defp format_lines(string) do
    String.replace(string, "\n", "<br>")
  end
end
