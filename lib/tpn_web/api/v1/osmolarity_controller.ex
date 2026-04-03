defmodule TpnWeb.Api.V1.OsmolarityController do
  use TpnWeb, :controller

  alias Tpn.Calculations.OsmolarityValidation
  alias Tpn.Lab.Osmolarity

  @doc """
  Get osmolarity limit for a given patient type and vascular access.

  ## Parameters
  - patient_type_id: ID of the patient type
  - vascular_access_id: ID of the vascular access type

  ## Returns
  JSON response with osmolarity limit data or error message
  """
  def get_limit(conn, %{
        "patient_type_id" => patient_type_id,
        "vascular_access_id" => vascular_access_id
      }) do
    case OsmolarityValidation.get_osmolarity_limit_api(
           String.to_integer(patient_type_id),
           String.to_integer(vascular_access_id)
         ) do
      %{success: true, data: data, message: message} ->
        json(conn, %{
          success: true,
          data: data,
          message: message
        })

      %{success: false, data: nil, message: message} ->
        json(conn, %{
          success: false,
          data: nil,
          message: message
        })
    end
  end

  def get_limit(conn, _params) do
    json(conn, %{
      success: false,
      data: nil,
      message: "Missing required parameters: patient_type_id and vascular_access_id"
    })
  end

  @doc """
  Validate osmolarity against limits.

  ## Parameters
  - calculated_osmolarity: The calculated osmolarity value
  - patient_type_id: ID of the patient type
  - vascular_access_id: ID of the vascular access type

  ## Returns
  JSON response with validation results
  """
  def validate(conn, %{
        "calculated_osmolarity" => calculated_osmolarity_str,
        "patient_type_id" => patient_type_id,
        "vascular_access_id" => vascular_access_id
      }) do
    # Parse parameters
    calculated_osmolarity =
      case Decimal.parse(calculated_osmolarity_str) do
        {decimal, _} -> decimal
        :error -> Decimal.new(0)
      end

    patient_type_id_int = String.to_integer(patient_type_id)
    vascular_access_id_int = String.to_integer(vascular_access_id)

    # Get osmolarity limit
    case OsmolarityValidation.get_osmolarity_limit(
           patient_type_id_int,
           vascular_access_id_int
         ) do
      {:ok, osmolarity_limit} ->
        # Validate osmolarity
        validation_result =
          OsmolarityValidation.validate_osmolarity(calculated_osmolarity, osmolarity_limit)

        # Determine if order can proceed
        can_proceed_result = OsmolarityValidation.can_proceed_with_order(validation_result, false)

        json(conn, %{
          success: true,
          data: %{
            validation: validation_result,
            can_proceed: can_proceed_result,
            limit_record: %{
              id: osmolarity_limit.id,
              name: osmolarity_limit.name,
              osmolarity: Decimal.to_float(osmolarity_limit.osmolarity),
              alert_type: osmolarity_limit.alert_type,
              patient_type_id: osmolarity_limit.patient_type_id,
              vascular_access_id: osmolarity_limit.vascular_access_id
            }
          },
          message: "Osmolarity validation completed"
        })

      {:error, :not_found} ->
        json(conn, %{
          success: false,
          data: nil,
          message:
            "No osmolarity limit configured for patient type #{patient_type_id} and vascular access #{vascular_access_id}"
        })

      {:error, :multiple_records} ->
        json(conn, %{
          success: false,
          data: nil,
          message:
            "Multiple osmolarity limits found for patient type #{patient_type_id} and vascular access #{vascular_access_id}"
        })
    end
  end

  def validate(conn, _params) do
    json(conn, %{
      success: false,
      data: nil,
      message:
        "Missing required parameters: calculated_osmolarity, patient_type_id, and vascular_access_id"
    })
  end

  @doc """
  Validate osmolarity with user comments for override.

  ## Parameters
  - calculated_osmolarity: The calculated osmolarity value
  - patient_type_id: ID of the patient type
  - vascular_access_id: ID of the vascular access type
  - has_comments: Boolean indicating if user has provided comments

  ## Returns
  JSON response with validation results including override decision
  """
  def validate_with_override(conn, %{
        "calculated_osmolarity" => calculated_osmolarity_str,
        "patient_type_id" => patient_type_id,
        "vascular_access_id" => vascular_access_id,
        "has_comments" => has_comments_str
      }) do
    # Parse parameters
    calculated_osmolarity =
      case Decimal.parse(calculated_osmolarity_str) do
        {decimal, _} -> decimal
        :error -> Decimal.new(0)
      end

    patient_type_id_int = String.to_integer(patient_type_id)
    vascular_access_id_int = String.to_integer(vascular_access_id)
    has_comments = has_comments_str == "true"

    # Get osmolarity limit
    case OsmolarityValidation.get_osmolarity_limit(
           patient_type_id_int,
           vascular_access_id_int
         ) do
      {:ok, osmolarity_limit} ->
        # Validate osmolarity
        validation_result =
          OsmolarityValidation.validate_osmolarity(calculated_osmolarity, osmolarity_limit)

        # Determine if order can proceed with comments
        can_proceed_result =
          OsmolarityValidation.can_proceed_with_order(validation_result, has_comments)

        json(conn, %{
          success: true,
          data: %{
            validation: validation_result,
            can_proceed: can_proceed_result,
            limit_record: %{
              id: osmolarity_limit.id,
              name: osmolarity_limit.name,
              osmolarity: Decimal.to_float(osmolarity_limit.osmolarity),
              alert_type: osmolarity_limit.alert_type,
              patient_type_id: osmolarity_limit.patient_type_id,
              vascular_access_id: osmolarity_limit.vascular_access_id
            }
          },
          message: "Osmolarity validation with override completed"
        })

      {:error, :not_found} ->
        json(conn, %{
          success: false,
          data: nil,
          message:
            "No osmolarity limit configured for patient type #{patient_type_id} and vascular access #{vascular_access_id}"
        })

      {:error, :multiple_records} ->
        json(conn, %{
          success: false,
          data: nil,
          message:
            "Multiple osmolarity limits found for patient type #{patient_type_id} and vascular access #{vascular_access_id}"
        })
    end
  end

  def validate_with_override(conn, _params) do
    json(conn, %{
      success: false,
      data: nil,
      message:
        "Missing required parameters: calculated_osmolarity, patient_type_id, vascular_access_id, and has_comments"
    })
  end

  @doc """
  Calculate total osmoles from products data.

  ## Parameters
  - products_data: JSON array of product objects

  ## Returns
  JSON response with total osmoles calculation
  """
  def calculate_total_osmoles(conn, %{"products_data" => products_data_json}) do
    # Parse products data
    products_data =
      case Jason.decode(products_data_json) do
        {:ok, data} -> data
        {:error, _} -> []
      end

    # Calculate total osmoles
    total_osmoles = OsmolarityValidation.calculate_total_osmoles(products_data)

    json(conn, %{
      success: true,
      data: %{
        total_osmoles: Decimal.to_float(total_osmoles)
      },
      message: "Total osmoles calculated successfully"
    })
  end

  def calculate_total_osmoles(conn, _params) do
    json(conn, %{
      success: false,
      data: nil,
      message: "Missing required parameter: products_data"
    })
  end

  @doc """
  Calculate osmolarity from total osmoles and total volume.

  ## Parameters
  - total_osmoles: Total osmoles value
  - total_volume_ml: Total volume in milliliters

  ## Returns
  JSON response with osmolarity calculation
  """
  def calculate_osmolarity(conn, %{
        "total_osmoles" => total_osmoles_str,
        "total_volume_ml" => total_volume_ml_str
      }) do
    # Parse parameters
    total_osmoles =
      case Decimal.parse(total_osmoles_str) do
        {decimal, _} -> decimal
        :error -> Decimal.new(0)
      end

    total_volume_ml =
      case Decimal.parse(total_volume_ml_str) do
        {decimal, _} -> decimal
        :error -> Decimal.new(0)
      end

    # Calculate osmolarity
    osmolarity = OsmolarityValidation.calculate_osmolarity(total_osmoles, total_volume_ml)

    json(conn, %{
      success: true,
      data: %{
        osmolarity: Decimal.to_float(osmolarity)
      },
      message: "Osmolarity calculated successfully"
    })
  end

  def calculate_osmolarity(conn, _params) do
    json(conn, %{
      success: false,
      data: nil,
      message: "Missing required parameters: total_osmoles and total_volume_ml"
    })
  end
end
