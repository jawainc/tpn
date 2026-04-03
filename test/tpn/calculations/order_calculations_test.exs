defmodule Tpn.Calculations.OrderCalculationsTest do
  use ExUnit.Case, async: true

  alias Tpn.Calculations.OrderCalculations
  alias Decimal, as: D

  describe "calculate_order_values/3 - osmolarity calculation" do
    setup do
      order_attrs = %{
        "tpn_infusion_duration_hours" => "24",
        "lipid_infusion_duration_hours" => "24",
        "dosing_weight" => "70",
        "tpn_infusion_type" => "3_in_1",
        "infusion_duration_type" => "Continuous"
      }

      template = %{
        fluids: 1000,
        bag_over_fill_volume: 100
      }

      %{order_attrs: order_attrs, template: template}
    end

    test "calculates osmolarity correctly with multiple products", %{
      order_attrs: order_attrs,
      template: template
    } do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 800,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 200,
          volume: 500,
          osmolarity: 1000,
          electrolyte_contributions: %{}
        },
        %{
          id: 3,
          class_name: "Lipid",
          dose: 50,
          volume: 250,
          osmolarity: 300,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Total osmoles = (800 * 250) + (1000 * 500) + (300 * 250) = 200,000 + 500,000 + 75,000 = 775,000
      # Total volume = 250 + 500 + 250 = 1000 mL
      # Osmolarity = (775,000 / 1000) * 1000 = 775 mOsm/L
      expected_osmolarity = 775.0

      assert_in_delta(
        D.to_float(result.nutritional_calculations.osmolarity),
        expected_osmolarity,
        0.1
      )
    end

    test "handles zero osmolarity products", %{order_attrs: order_attrs, template: template} do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 0,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 200,
          volume: 500,
          osmolarity: 0,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      assert D.equal?(result.nutritional_calculations.osmolarity, D.new(0))
    end

    test "handles empty products list", %{order_attrs: order_attrs, template: template} do
      products_data = []

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      assert D.equal?(result.nutritional_calculations.osmolarity, D.new(0))
    end

    test "handles nil osmolarity values", %{order_attrs: order_attrs, template: template} do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: nil,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 200,
          volume: 500,
          osmolarity: 1000,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Only dextrose contributes: (1000 * 500) / 750 * 1000 = 666.67 mOsm/L
      expected_osmolarity = 666.67

      assert_in_delta(
        D.to_float(result.nutritional_calculations.osmolarity),
        expected_osmolarity,
        0.1
      )
    end

    test "handles nil volume values", %{order_attrs: order_attrs, template: template} do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: nil,
          osmolarity: 800,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 200,
          volume: 500,
          osmolarity: 1000,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Only dextrose contributes: (1000 * 500) / 500 * 1000 = 1000 mOsm/L
      expected_osmolarity = 1000.0

      assert_in_delta(
        D.to_float(result.nutritional_calculations.osmolarity),
        expected_osmolarity,
        0.1
      )
    end

    test "calculates osmolarity with decimal precision", %{
      order_attrs: order_attrs,
      template: template
    } do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 333.33,
          osmolarity: 856.5,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 200,
          volume: 666.67,
          osmolarity: 1025.8,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Total osmoles = (856.5 * 333.33) + (1025.8 * 666.67)
      # = 285,464.145 + 684,054.086 = 969,518.231
      # Total volume = 333.33 + 666.67 = 1000
      # Osmolarity = (969,518.231 / 1000) * 1000 = 969.518 mOsm/L
      expected_osmolarity = 969.52

      assert_in_delta(
        D.to_float(result.nutritional_calculations.osmolarity),
        expected_osmolarity,
        0.1
      )
    end
  end

  describe "calculate_order_values/3 - nutritional calculations" do
    setup do
      order_attrs = %{
        "tpn_infusion_duration_hours" => "24",
        "lipid_infusion_duration_hours" => "24",
        "dosing_weight" => "70",
        "tpn_infusion_type" => "3_in_1",
        "infusion_duration_type" => "Continuous"
      }

      template = %{
        fluids: 1000,
        bag_over_fill_volume: 100
      }

      %{order_attrs: order_attrs, template: template}
    end

    test "calculates GIR correctly", %{order_attrs: order_attrs, template: template} do
      products_data = [
        %{
          id: 1,
          class_name: "Dextrose",
          dose: 200,
          volume: 500,
          osmolarity: 1000,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # GIR = (dextrose_dose_g * 1000) / (dosing_weight * duration_hours * 60)
      # GIR = (200 * 1000) / (70 * 24 * 60) = 200,000 / 100,800 = 1.98 mg/kg/min
      expected_gir = 1.98

      assert_in_delta(D.to_float(result.nutritional_calculations.gir), expected_gir, 0.01)
    end

    test "calculates amino acid percentage correctly", %{
      order_attrs: order_attrs,
      template: template
    } do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 800,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Amino acid % = (dose_g / bag_volume_ml) * 100
      # = (50 / 1000) * 100 = 5%
      expected_percentage = 5.0

      assert_in_delta(
        D.to_float(result.nutritional_calculations.amino_acid_percent),
        expected_percentage,
        0.01
      )
    end

    test "calculates fat infusion rate correctly", %{
      order_attrs: order_attrs,
      template: template
    } do
      products_data = [
        %{
          id: 1,
          class_name: "Lipid",
          dose: 50,
          volume: 250,
          osmolarity: 300,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Fat infusion rate = lipid_dose / (dosing_weight * duration)
      # = 50 / (70 * 24) = 50 / 1680 = 0.0298 g/kg/hr
      expected_rate = 0.03

      assert_in_delta(
        D.to_float(result.nutritional_calculations.fat_infusion_rate),
        expected_rate,
        0.01
      )
    end
  end

  describe "calculate_order_values/3 - electrolyte summary" do
    setup do
      order_attrs = %{
        "tpn_infusion_duration_hours" => "24",
        "lipid_infusion_duration_hours" => "24",
        "dosing_weight" => "70",
        "tpn_infusion_type" => "3_in_1"
      }

      template = %{
        fluids: 1000,
        bag_over_fill_volume: 100
      }

      %{order_attrs: order_attrs, template: template}
    end

    test "calculates electrolyte totals correctly", %{
      order_attrs: order_attrs,
      template: template
    } do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 800,
          electrolyte_contributions: %{
            "sodium" => 10,
            "potassium" => 5,
            "calcium" => 2
          }
        },
        %{
          id: 2,
          class_name: "Electrolyte",
          dose: 10,
          volume: 50,
          osmolarity: 500,
          electrolyte_contributions: %{
            "sodium" => 20,
            "chloride" => 15,
            "magnesium" => 3
          }
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      assert D.equal?(result.electrolyte_summary.sodium, D.new(30))
      assert D.equal?(result.electrolyte_summary.potassium, D.new(5))
      assert D.equal?(result.electrolyte_summary.calcium, D.new(2))
      assert D.equal?(result.electrolyte_summary.chloride, D.new(15))
      assert D.equal?(result.electrolyte_summary.magnesium, D.new(3))
    end

    test "handles missing electrolyte contributions", %{
      order_attrs: order_attrs,
      template: template
    } do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 800,
          electrolyte_contributions: nil
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      assert D.equal?(result.electrolyte_summary.sodium, D.new(0))
      assert D.equal?(result.electrolyte_summary.potassium, D.new(0))
    end
  end

  describe "calculate_order_values/3 - nutritional summary" do
    setup do
      order_attrs = %{
        "tpn_infusion_duration_hours" => "24",
        "lipid_infusion_duration_hours" => "24",
        "dosing_weight" => "70",
        "tpn_infusion_type" => "3_in_1"
      }

      template = %{
        fluids: 1000,
        bag_over_fill_volume: 100
      }

      %{order_attrs: order_attrs, template: template}
    end

    test "calculates energy values correctly", %{order_attrs: order_attrs, template: template} do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 800,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 200,
          volume: 500,
          osmolarity: 1000,
          electrolyte_contributions: %{}
        },
        %{
          id: 3,
          class_name: "Lipid",
          dose: 50,
          volume: 250,
          osmolarity: 300,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Protein energy = 50 * 4 = 200 kcal
      # Dextrose energy = 200 * 3.4 = 680 kcal
      # Lipid energy = 50 * 9 = 450 kcal
      # Total energy = 200 + 680 + 450 = 1330 kcal

      assert_in_delta(D.to_float(result.nutritional_summary.protein_energy), 200.0, 0.1)
      assert_in_delta(D.to_float(result.nutritional_summary.dextrose_energy), 680.0, 0.1)
      assert_in_delta(D.to_float(result.nutritional_summary.lipid_energy), 450.0, 0.1)
      assert_in_delta(D.to_float(result.nutritional_summary.total_energy), 1330.0, 0.1)
    end

    test "calculates nitrogen correctly", %{order_attrs: order_attrs, template: template} do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 800,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Nitrogen = amino_acid_dose * 0.16 = 50 * 0.16 = 8 g
      assert_in_delta(D.to_float(result.nutritional_summary.nitrogen), 8.0, 0.1)
    end

    test "calculates kcal per nitrogen ratios", %{order_attrs: order_attrs, template: template} do
      products_data = [
        %{
          id: 1,
          class_name: "Amino Acid",
          dose: 50,
          volume: 250,
          osmolarity: 800,
          electrolyte_contributions: %{}
        },
        %{
          id: 2,
          class_name: "Dextrose",
          dose: 200,
          volume: 500,
          osmolarity: 1000,
          electrolyte_contributions: %{}
        }
      ]

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      # Nitrogen = 50 * 0.16 = 8 g
      # Total energy = (50 * 4) + (200 * 3.4) = 200 + 680 = 880 kcal
      # Total kcal/N = 880 / 8 = 110 kcal/g N

      assert_in_delta(
        D.to_float(result.nutritional_summary.total_kcal_per_nitrogen),
        110.0,
        0.1
      )
    end
  end

  describe "calculate_order_values/3 - metadata" do
    test "includes calculated_at timestamp" do
      order_attrs = %{
        "tpn_infusion_duration_hours" => "24",
        "dosing_weight" => "70"
      }

      template = %{fluids: 1000, bag_over_fill_volume: 100}
      products_data = []

      result = OrderCalculations.calculate_order_values(order_attrs, template, products_data)

      assert Map.has_key?(result, :calculated_at)
      assert %DateTime{} = result.calculated_at
    end
  end
end
