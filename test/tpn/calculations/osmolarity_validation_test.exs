defmodule Tpn.Calculations.OsmolarityValidationTest do
  use ExUnit.Case, async: true

  alias Tpn.Calculations.OsmolarityValidation

  describe "calculate_total_osmoles/1" do
    test "calculates total osmoles from products data" do
      products_data = [
        %{osmolarity: 100, volume: 500},
        %{osmolarity: 200, volume: 250},
        %{osmolarity: 50, volume: 1000}
      ]

      total_osmoles = OsmolarityValidation.calculate_total_osmoles(products_data)

      # Expected: (100 * 500) + (200 * 250) + (50 * 1000) = 50,000 + 50,000 + 50,000 = 150,000
      assert Decimal.equal?(total_osmoles, Decimal.new(150_000))
    end

    test "handles missing osmolarity or volume" do
      products_data = [
        %{osmolarity: nil, volume: 500},
        %{osmolarity: 200, volume: nil},
        %{osmolarity: 50, volume: 1000}
      ]

      total_osmoles = OsmolarityValidation.calculate_total_osmoles(products_data)

      # Expected: (0 * 500) + (200 * 0) + (50 * 1000) = 0 + 0 + 50,000 = 50,000
      assert Decimal.equal?(total_osmoles, Decimal.new(50_000))
    end

    test "returns zero for empty list" do
      total_osmoles = OsmolarityValidation.calculate_total_osmoles([])
      assert Decimal.equal?(total_osmoles, Decimal.new(0))
    end
  end

  describe "calculate_osmolarity/2" do
    test "calculates osmolarity from total osmoles and volume" do
      total_osmoles = Decimal.new(150_000)
      # 500 + 250 + 1000
      total_volume_ml = Decimal.new(1750)

      osmolarity = OsmolarityValidation.calculate_osmolarity(total_osmoles, total_volume_ml)

      # Expected: (150,000 / 1750) * 1000 = 85.714 * 1000 = 85,714.2857...
      expected =
        Decimal.div(Decimal.new(150_000), Decimal.new(1750))
        |> Decimal.mult(Decimal.new(1000))

      assert Decimal.equal?(osmolarity, expected)
    end

    test "returns zero when total volume is zero" do
      total_osmoles = Decimal.new(150_000)
      total_volume_ml = Decimal.new(0)

      osmolarity = OsmolarityValidation.calculate_osmolarity(total_osmoles, total_volume_ml)
      assert Decimal.equal?(osmolarity, Decimal.new(0))
    end

    test "handles zero total osmoles" do
      total_osmoles = Decimal.new(0)
      total_volume_ml = Decimal.new(1000)

      osmolarity = OsmolarityValidation.calculate_osmolarity(total_osmoles, total_volume_ml)
      assert Decimal.equal?(osmolarity, Decimal.new(0))
    end
  end

  describe "validate_osmolarity/2" do
    setup do
      osmolarity_limit_record = %{
        osmolarity: Decimal.new(900),
        alert_type: "Soft",
        patient_type_id: 1,
        vascular_access_id: 2
      }

      %{limit_record: osmolarity_limit_record}
    end

    test "returns validation result when osmolarity is within limit", %{
      limit_record: limit_record
    } do
      calculated_osmolarity = Decimal.new(800)

      result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, limit_record)

      assert result.exceeds == false
      assert result.limit == 900.0
      assert result.calculated == 800.0
      assert result.exceeds_limit == 0
      assert result.alert_type == "Soft"
      assert result.patient_type_id == 1
      assert result.vascular_access_id == 2
      assert is_binary(result.checked_at)
    end

    test "returns validation result when osmolarity exceeds limit", %{limit_record: limit_record} do
      calculated_osmolarity = Decimal.new(1000)

      result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, limit_record)

      assert result.exceeds == true
      assert result.limit == 900.0
      assert result.calculated == 1000.0
      assert result.exceeds_limit == 100.0
      assert result.alert_type == "Soft"
    end

    test "handles hard alert type", %{limit_record: limit_record} do
      limit_record = Map.put(limit_record, :alert_type, "Hard")
      calculated_osmolarity = Decimal.new(1000)

      result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, limit_record)

      assert result.exceeds == true
      assert result.alert_type == "Hard"
    end
  end

  describe "can_proceed_with_order/2" do
    test "allows proceeding when osmolarity is within limits" do
      alert_result = %{exceeds: false, alert_type: "Soft"}

      result = OsmolarityValidation.can_proceed_with_order(alert_result)

      assert result.can_proceed == true
      assert result.type == "info"
      assert result.message == "Osmolarity is within safe limits."
    end

    test "allows proceeding with soft limit when comments provided" do
      alert_result = %{exceeds: true, alert_type: "Soft"}

      result = OsmolarityValidation.can_proceed_with_order(alert_result, true)

      assert result.can_proceed == true
      assert result.type == "warning"

      assert result.message ==
               "Osmolarity exceeds soft limit but order can proceed with comments."
    end

    test "prevents proceeding with soft limit when no comments" do
      alert_result = %{exceeds: true, alert_type: "Soft"}

      result = OsmolarityValidation.can_proceed_with_order(alert_result, false)

      assert result.can_proceed == false
      assert result.type == "warning"

      assert result.message ==
               "Osmolarity exceeds soft limit. Please provide comments to proceed."
    end

    test "prevents proceeding with hard limit even with comments" do
      alert_result = %{exceeds: true, alert_type: "Hard"}

      result = OsmolarityValidation.can_proceed_with_order(alert_result, true)

      assert result.can_proceed == false
      assert result.type == "error"

      assert result.message ==
               "Osmolarity exceeds hard limit. Order cannot proceed even with comments."
    end

    test "prevents proceeding with hard limit without comments" do
      alert_result = %{exceeds: true, alert_type: "Hard"}

      result = OsmolarityValidation.can_proceed_with_order(alert_result, false)

      assert result.can_proceed == false
      assert result.type == "error"
      assert result.message == "Osmolarity exceeds hard limit. Order cannot proceed."
    end
  end

  describe "get_osmolarity_limit_api/2" do
    test "returns API response structure" do
      # This is a unit test that doesn't hit the database
      # We're testing the function signature and return structure

      # Mock the actual get_osmolarity_limit/2 function behavior
      # by testing that the API wrapper returns the expected structure
      # In a real test with database, we would set up test data

      # For now, just test that the function exists and returns a map
      result = OsmolarityValidation.get_osmolarity_limit_api(1, 2)

      assert is_map(result)
      assert Map.has_key?(result, :success)
      assert Map.has_key?(result, :data)
      assert Map.has_key?(result, :message)
    end
  end
end
