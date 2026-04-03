defmodule Tpn.Calculations.OsmolarityValidation do
  @moduledoc """
  Service for validating TPN order osmolarity against clinical limits.

  This module provides functions to:
  1. Retrieve osmolarity limits based on patient type and vascular access
  2. Validate calculated osmolarity against limits
  3. Determine if an order can proceed based on validation results
  4. Handle osmolarity alerts and overrides
  """

  import Ecto.Query

  alias Tpn.Lab.Osmolarity
  alias Tpn.Repo

  @doc """
  Get the osmolarity limit for a given patient type and vascular access.

  ## Parameters
  - patient_type_id: ID of the patient type (e.g., neonate, pediatric, adult)
  - vascular_access_id: ID of the vascular access type (e.g., peripheral, central)

  ## Returns
  - {:ok, osmolarity_limit_record} if a limit is found
  - {:error, :not_found} if no limit is configured
  - {:error, :multiple_records} if multiple limits are found (should not happen with unique constraints)
  """
  def get_osmolarity_limit(patient_type_id, vascular_access_id) do
    query =
      from o in Osmolarity,
        where: o.patient_type_id == ^patient_type_id,
        where: o.vascular_access_id == ^vascular_access_id

    case Repo.all(query) do
      [] ->
        {:error, :not_found}

      [osmolarity_limit] ->
        {:ok, osmolarity_limit}

      _multiple ->
        {:error, :multiple_records}
    end
  end

  @doc """
  Validate calculated osmolarity against the osmolarity limit.

  ## Parameters
  - calculated_osmolarity: The calculated osmolarity value (mOsm/L)
  - osmolarity_limit_record: The osmolarity limit record from the database

  ## Returns
  A map with validation results:
  - exceeds: boolean indicating if the limit is exceeded
  - limit: the osmolarity limit value
  - calculated: the calculated osmolarity value
  - exceeds_limit: the amount by which the limit is exceeded (0 if not exceeded)
  - alert_type: "Soft" or "Hard" alert from the limit record
  - patient_type_id: patient type ID from the limit record
  - vascular_access_id: vascular access ID from the limit record
  - checked_at: timestamp of validation
  """
  def validate_osmolarity(calculated_osmolarity, osmolarity_limit_record) do
    limit = Decimal.to_float(osmolarity_limit_record.osmolarity)
    calculated = Decimal.to_float(calculated_osmolarity)
    exceeds = calculated > limit
    exceeds_limit = if exceeds, do: calculated - limit, else: 0

    %{
      exceeds: exceeds,
      limit: limit,
      calculated: calculated,
      exceeds_limit: exceeds_limit,
      alert_type: osmolarity_limit_record.alert_type,
      patient_type_id: osmolarity_limit_record.patient_type_id,
      vascular_access_id: osmolarity_limit_record.vascular_access_id,
      checked_at: DateTime.utc_now()
    }
  end

  @doc """
  Determine if an order can proceed based on osmolarity validation results.

  ## Parameters
  - alert_result: The result map from validate_osmolarity/2
  - has_comments: Boolean indicating if the user has provided comments for override

  ## Returns
  A map with:
  - can_proceed: boolean indicating if the order can proceed
  - type: "info", "warning", or "error"
  - message: human-readable message explaining the result
  """
  def can_proceed_with_order(alert_result, has_comments \\ false) do
    case {alert_result.exceeds, alert_result.alert_type, has_comments} do
      {false, _, _} ->
        %{
          can_proceed: true,
          type: "info",
          message: "Osmolarity is within safe limits."
        }

      {true, "Soft", true} ->
        %{
          can_proceed: true,
          type: "warning",
          message: "Osmolarity exceeds soft limit but order can proceed with comments."
        }

      {true, "Soft", false} ->
        %{
          can_proceed: false,
          type: "warning",
          message: "Osmolarity exceeds soft limit. Please provide comments to proceed."
        }

      {true, "Hard", true} ->
        %{
          can_proceed: false,
          type: "error",
          message: "Osmolarity exceeds hard limit. Order cannot proceed even with comments."
        }

      {true, "Hard", false} ->
        %{
          can_proceed: false,
          type: "error",
          message: "Osmolarity exceeds hard limit. Order cannot proceed."
        }
    end
  end

  @doc """
  API-friendly version of get_osmolarity_limit/2 that returns a standardized response.

  ## Parameters
  - patient_type_id: ID of the patient type
  - vascular_access_id: ID of the vascular access type

  ## Returns
  A map with:
  - success: boolean indicating if the operation was successful
  - data: the osmolarity limit record or error details
  - message: human-readable message
  """
  def get_osmolarity_limit_api(patient_type_id, vascular_access_id) do
    case get_osmolarity_limit(patient_type_id, vascular_access_id) do
      {:ok, osmolarity_limit} ->
        %{
          success: true,
          data: %{
            id: osmolarity_limit.id,
            name: osmolarity_limit.name,
            osmolarity: Decimal.to_float(osmolarity_limit.osmolarity),
            alert_type: osmolarity_limit.alert_type,
            patient_type_id: osmolarity_limit.patient_type_id,
            vascular_access_id: osmolarity_limit.vascular_access_id,
            unit_id: osmolarity_limit.unit_id
          },
          message: "Osmolarity limit found"
        }

      {:error, :not_found} ->
        %{
          success: false,
          data: nil,
          message:
            "No osmolarity limit configured for this patient type and vascular access combination"
        }

      {:error, :multiple_records} ->
        %{
          success: false,
          data: nil,
          message: "Multiple osmolarity limits found for this combination (configuration error)"
        }
    end
  end

  @doc """
  Calculate total osmoles from product data.

  ## Parameters
  - products_data: List of product maps with osmolarity and volume information

  ## Returns
  Total osmoles as a Decimal
  """
  def calculate_total_osmoles(products_data) do
    Enum.reduce(products_data, Decimal.new(0), fn product, acc ->
      osmolarity = Decimal.new(product.osmolarity || 0)
      volume = Decimal.new(product.volume || 0)
      osmoles = Decimal.mult(osmolarity, volume)
      Decimal.add(acc, osmoles)
    end)
  end

  @doc """
  Calculate osmolarity (mOsm/L) from total osmoles and total volume.

  ## Parameters
  - total_osmoles: Total osmoles as Decimal
  - total_volume_ml: Total volume in milliliters as Decimal

  ## Returns
  Osmolarity in mOsm/L as Decimal
  """
  def calculate_osmolarity(total_osmoles, total_volume_ml) do
    if Decimal.eq?(total_volume_ml, 0) do
      Decimal.new(0)
    else
      # Convert to mOsm/L: (total_osmoles / total_volume_ml) * 1000
      Decimal.div(total_osmoles, total_volume_ml)
      |> Decimal.mult(Decimal.new(1000))
    end
  end
end
