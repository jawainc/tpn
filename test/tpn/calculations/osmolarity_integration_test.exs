defmodule Tpn.Calculations.OsmolarityIntegrationTest do
  use Tpn.DataCase, async: true

  alias Tpn.Calculations.{OsmolarityValidation, OrderCalculations}
  alias Tpn.Lab.{Osmolarity, PatientType, VascularAccess}
  alias Tpn.Repo
  alias Decimal, as: D

  describe "complete osmolarity calculation and validation flow" do
    setup do
      # Create test patient type and vascular access
      {:ok, patient_type} =
        %PatientType{}
        |> PatientType.changeset(%{name: "Adult", user_id: 1})
        |> Repo.insert()

      {:ok, vascular_access} =
        %VascularAccess{}
        |> VascularAccess.changeset(%{name: "Peripheral", user_id: 1})
        |> Repo.insert()

      # Create soft limit
      {:ok, soft_limit} =
        %Osmolarity{}
        |> Osmolarity.changeset(%{
          osmolarity: D.new(900),
          alert_type: "Soft",
          patient_type_id: patient_type.id,
          vascular_access_id: vascular_access.id,
          user_id: 1
        })
        |> Repo.insert()

      # Create hard limit for different vascular access
      {:ok, central_access} =
        %VascularAccess{}
        |> VascularAccess.changeset(%{name: "Central", user_id: 1})
        |> Repo.insert()

      {:ok, hard_limit} =
        %Osmolarity{}
        |> Osmolarity.changeset(%{
          osmolarity: D.new(1200),
          alert_type: "Hard",
          patient_type_id: patient_type.id,
          vascular_access_id: central_access.id,
          user_id: 1
        })
        |> Repo.insert()

      %{
        patient_type: patient_type,
        peripheral_access: vascular_access,
        central_access: central_access,
        soft_limit: soft_limit,
        hard_limit: hard_limit
      }
    end

    test "calculates and validates osmolarity within soft limit", %{
      patient_type: patient_type,
      peripheral_access: peripheral_access,
      soft_limit: soft_limit
    } do
      # Step 1: Calculate osmolarity from order
      order_attrs = %{
        "tpn_infusion_duration_hours" => "24",
        "lipid_infusion_duration_hours" => "24",
        "dosing_weight" => "70",
        "tpn_infusion_type" => "3_in_1"
      }

      template = %{fluids: 1000, bag_over_fill_volume: 100}

      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 500,
          osmolarity: 800,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 100,
          volume: 500,
          osmolarity: 1000,
          electrolyte_contributions: %{}
        }
      ]

      calculations = OrderCalculations.calculate_order_values(order_attrs, template, products_data)
      calculated_osmolarity = calculations.nutritional_calculations.osmolarity

      # Expected: (800 * 500 + 1000 * 500) / 1000 * 1000 = 900,000 / 1000 = 900 mOsm/L
      assert_in_delta(D.to_float(calculated_osmolarity), 900.0, 0.1)

      # Step 2: Get osmolarity limit from database
      {:ok, limit_record} =
        OsmolarityValidation.get_osmolarity_limit(patient_type.id, peripheral_access.id)

      assert limit_record.id == soft_limit.id
      assert D.equal?(limit_record.osmolarity, D.new(900))

      # Step 3: Validate osmolarity
      validation_result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, limit_record)

      assert validation_result.exceeds == false
      assert validation_result.alert_type == "Soft"

      # Step 4: Check if order can proceed
      proceed_result = OsmolarityValidation.can_proceed_with_order(validation_result, false)

      assert proceed_result.can_proceed == true
      assert proceed_result.type == "info"
    end

    test "calculates and validates osmolarity exceeding soft limit without comments", %{
      patient_type: patient_type,
      peripheral_access: peripheral_access
    } do
      order_attrs = %{
        "tpn_infusion_duration_hours" => "24",
        "dosing_weight" => "70"
      }

      template = %{fluids: 1000, bag_over_fill_volume: 100}

      products_data = [
        %{
          id: 1,
          class_name: "Dextrose",
          dose: 200,
          volume: 1000,
          osmolarity: 1100,
          electrolyte_contributions: %{}
        }
      ]

      calculations = OrderCalculations.calculate_order_values(order_attrs, template, products_data)
      calculated_osmolarity = calculations.nutritional_calculations.osmolarity

      # Expected: (1100 * 1000) / 1000 * 1000 = 1100 mOsm/L
      assert_in_delta(D.to_float(calculated_osmolarity), 1100.0, 0.1)

      {:ok, limit_record} =
        OsmolarityValidation.get_osmolarity_limit(patient_type.id, peripheral_access.id)

      validation_result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, limit_record)

      assert validation_result.exceeds == true
      assert validation_result.exceeds_limit == 200.0

      proceed_result = OsmolarityValidation.can_proceed_with_order(validation_result, false)

      assert proceed_result.can_proceed == false
      assert proceed_result.type == "warning"
    end

    test "calculates and validates osmolarity exceeding soft limit with comments", %{
      patient_type: patient_type,
      peripheral_access: peripheral_access
    } do
      order_attrs = %{"tpn_infusion_duration_hours" => "24", "dosing_weight" => "70"}
      template = %{fluids: 1000, bag_over_fill_volume: 100}

      products_data = [
        %{
          id: 1,
          class_name: "Dextrose",
          dose: 200,
          volume: 1000,
          osmolarity: 1100,
          electrolyte_contributions: %{}
        }
      ]

      calculations = OrderCalculations.calculate_order_values(order_attrs, template, products_data)
      calculated_osmolarity = calculations.nutritional_calculations.osmolarity

      {:ok, limit_record} =
        OsmolarityValidation.get_osmolarity_limit(patient_type.id, peripheral_access.id)

      validation_result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, limit_record)

      # With comments, soft limit can be overridden
      proceed_result = OsmolarityValidation.can_proceed_with_order(validation_result, true)

      assert proceed_result.can_proceed == true
      assert proceed_result.type == "warning"
      assert proceed_result.message =~ "can proceed with comments"
    end

    test "calculates and validates osmolarity exceeding hard limit", %{
      patient_type: patient_type,
      central_access: central_access
    } do
      order_attrs = %{"tpn_infusion_duration_hours" => "24", "dosing_weight" => "70"}
      template = %{fluids: 1000, bag_over_fill_volume: 100}

      products_data = [
        %{
          id: 1,
          class_name: "Dextrose",
          dose: 300,
          volume: 1000,
          osmolarity: 1500,
          electrolyte_contributions: %{}
        }
      ]

      calculations = OrderCalculations.calculate_order_values(order_attrs, template, products_data)
      calculated_osmolarity = calculations.nutritional_calculations.osmolarity

      # Expected: (1500 * 1000) / 1000 * 1000 = 1500 mOsm/L
      assert_in_delta(D.to_float(calculated_osmolarity), 1500.0, 0.1)

      {:ok, limit_record} =
        OsmolarityValidation.get_osmolarity_limit(patient_type.id, central_access.id)

      validation_result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, limit_record)

      assert validation_result.exceeds == true
      assert validation_result.alert_type == "Hard"
      assert validation_result.exceeds_limit == 300.0

      # Hard limit cannot be overridden even with comments
      proceed_result_with_comments = OsmolarityValidation.can_proceed_with_order(validation_result, true)
      proceed_result_without_comments = OsmolarityValidation.can_proceed_with_order(validation_result, false)

      assert proceed_result_with_comments.can_proceed == false
      assert proceed_result_without_comments.can_proceed == false
      assert proceed_result_with_comments.type == "error"
    end

    test "handles missing osmolarity limit gracefully", %{patient_type: patient_type} do
      # Create a vascular access with no osmolarity limit
      {:ok, new_access} =
        %VascularAccess{}
        |> VascularAccess.changeset(%{name: "Umbilical", user_id: 1})
        |> Repo.insert()

      result = OsmolarityValidation.get_osmolarity_limit(patient_type.id, new_access.id)

      assert result == {:error, :not_found}
    end

    test "handles multiple osmolarity limits for same patient type and vascular access", %{
      patient_type: patient_type,
      peripheral_access: peripheral_access
    } do
      # Insert duplicate osmolarity limit (should not happen in production)
      %Osmolarity{}
      |> Osmolarity.changeset(%{
        osmolarity: D.new(1000),
        alert_type: "Hard",
        patient_type_id: patient_type.id,
        vascular_access_id: peripheral_access.id,
        user_id: 1
      })
      |> Repo.insert!()

      result = OsmolarityValidation.get_osmolarity_limit(patient_type.id, peripheral_access.id)

      assert result == {:error, :multiple_records}
    end
  end

  describe "edge cases and boundary conditions" do
    test "handles exactly at limit boundary" do
      osmolarity_limit = %{
        osmolarity: D.new(900),
        alert_type: "Soft",
        patient_type_id: 1,
        vascular_access_id: 1
      }

      # Exactly at limit
      calculated_osmolarity = D.new(900)
      result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, osmolarity_limit)

      assert result.exceeds == false
      assert result.exceeds_limit == 0
    end

    test "handles just above limit boundary" do
      osmolarity_limit = %{
        osmolarity: D.new(900),
        alert_type: "Soft",
        patient_type_id: 1,
        vascular_access_id: 1
      }

      # Just above limit
      calculated_osmolarity = D.new("900.01")
      result = OsmolarityValidation.validate_osmolarity(calculated_osmolarity, osmolarity_limit)

      assert result.exceeds == true
      assert_in_delta(result.exceeds_limit, 0.01, 0.001)
    end

    test "handles very high osmolarity values" do
      products_data = [
        %{osmolarity: 5000, volume: 1000},
        %{osmolarity: 3000, volume: 500}
      ]

      total_osmoles = OsmolarityValidation.calculate_total_osmoles(products_data)
      # (5000 * 1000) + (3000 * 500) = 5,000,000 + 1,500,000 = 6,500,000
      assert D.equal?(total_osmoles, D.new(6_500_000))

      osmolarity = OsmolarityValidation.calculate_osmolarity(total_osmoles, D.new(1500))
      # 6,500,000 / 1500 * 1000 = 4,333.33 mOsm/L
      assert_in_delta(D.to_float(osmolarity), 4333.33, 0.1)
    end

    test "handles very small osmolarity values" do
      products_data = [
        %{osmolarity: 0.5, volume: 100},
        %{osmolarity: 0.3, volume: 50}
      ]

      total_osmoles = OsmolarityValidation.calculate_total_osmoles(products_data)
      # (0.5 * 100) + (0.3 * 50) = 50 + 15 = 65
      assert_in_delta(D.to_float(total_osmoles), 65.0, 0.1)

      osmolarity = OsmolarityValidation.calculate_osmolarity(total_osmoles, D.new(150))
      # 65 / 150 * 1000 = 433.33 mOsm/L
      assert_in_delta(D.to_float(osmolarity), 433.33, 0.1)
    end

    test "handles large number of products" do
      # Create 50 products
      products_data =
        Enum.map(1..50, fn i ->
          %{
            id: i,
            class_name: "Product #{i}",
            dose: 10,
            volume: 20,
            osmolarity: 100 + i,
            electrolyte_contributions: %{}
          }
        end)

      order_attrs = %{"tpn_infusion_duration_hours" => "24", "dosing_weight" => "70"}
      template = %{fluids: 1000, bag_over_fill_volume: 100}

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Should complete without error
      assert is_map(result)
      assert Map.has_key?(result, :nutritional_calculations)
      assert D.compare(result.nutritional_calculations.osmolarity, D.new(0)) == :gt
    end

    test "handles products with zero volume" do
      products_data = [
        %{osmolarity: 1000, volume: 0},
        %{osmolarity: 500, volume: 100}
      ]

      total_osmoles = OsmolarityValidation.calculate_total_osmoles(products_data)
      # (1000 * 0) + (500 * 100) = 0 + 50,000 = 50,000
      assert D.equal?(total_osmoles, D.new(50_000))

      osmolarity = OsmolarityValidation.calculate_osmolarity(total_osmoles, D.new(100))
      # 50,000 / 100 * 1000 = 500 mOsm/L
      assert_in_delta(D.to_float(osmolarity), 500.0, 0.1)
    end

    test "handles negative osmolarity values gracefully" do
      # Although this shouldn't happen in practice, test defensive programming
      products_data = [
        %{osmolarity: -100, volume: 100},
        %{osmolarity: 500, volume: 100}
      ]

      total_osmoles = OsmolarityValidation.calculate_total_osmoles(products_data)
      # (-100 * 100) + (500 * 100) = -10,000 + 50,000 = 40,000
      assert D.equal?(total_osmoles, D.new(40_000))
    end
  end

  describe "API response format validation" do
    setup do
      {:ok, patient_type} =
        %PatientType{}
        |> PatientType.changeset(%{name: "Test Patient", user_id: 1})
        |> Repo.insert()

      {:ok, vascular_access} =
        %VascularAccess{}
        |> VascularAccess.changeset(%{name: "Test Access", user_id: 1})
        |> Repo.insert()

      {:ok, osmolarity_limit} =
        %Osmolarity{}
        |> Osmolarity.changeset(%{
          osmolarity: D.new(900),
          alert_type: "Soft",
          patient_type_id: patient_type.id,
          vascular_access_id: vascular_access.id,
          user_id: 1
        })
        |> Repo.insert()

      %{
        patient_type: patient_type,
        vascular_access: vascular_access,
        osmolarity_limit: osmolarity_limit
      }
    end

    test "get_osmolarity_limit_api returns correct format on success", %{
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      result = OsmolarityValidation.get_osmolarity_limit_api(patient_type.id, vascular_access.id)

      assert result.success == true
      assert is_map(result.data)
      assert result.data.alert_type == "Soft"
      assert D.equal?(result.data.osmolarity, D.new(900))
      assert result.message == "Osmolarity limit found"
    end

    test "get_osmolarity_limit_api returns correct format on not found" do
      result = OsmolarityValidation.get_osmolarity_limit_api(999, 999)

      assert result.success == false
      assert result.data == nil
      assert result.message =~ "not found"
    end

    test "get_osmolarity_limit_api returns correct format on multiple records", %{
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      # Insert duplicate
      %Osmolarity{}
      |> Osmolarity.changeset(%{
        osmolarity: D.new(1000),
        alert_type: "Hard",
        patient_type_id: patient_type.id,
        vascular_access_id: vascular_access.id,
        user_id: 1
      })
      |> Repo.insert!()

      result = OsmolarityValidation.get_osmolarity_limit_api(patient_type.id, vascular_access.id)

      assert result.success == false
      assert result.data == nil
      assert result.message =~ "Multiple"
    end
  end
end
