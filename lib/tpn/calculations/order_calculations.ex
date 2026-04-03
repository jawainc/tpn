defmodule Tpn.Calculations.OrderCalculations do
  @moduledoc """
  Service for performing comprehensive TPN order calculations.

  This module handles:
  1. Infusion rate calculations (TPN rate, lipid rate, total fluids)
  2. Nutritional calculations (GIR, amino acid %, dextrose %, fat infusion rate, osmolarity)
  3. Electrolyte summary calculations
  4. Nutritional summary calculations
  5. Total osmoles calculation
  """

  alias Tpn.Calculations.OsmolarityValidation
  alias Decimal, as: D

  @doc """
  Calculate all order values based on order attributes, template, and products data.

  ## Parameters
  - order_attrs: Map of order attributes
  - template: Template struct
  - products_data: List of product maps with calculation data

  ## Returns
  Map containing all calculated values:
  - infusion_calculations: TPN rate, lipid rate, total fluids, custom TPN rate
  - nutritional_calculations: GIR, amino acid %, dextrose %, fat infusion rate, osmolarity
  - electrolyte_summary: Sodium, potassium, calcium, magnesium, phosphate, chloride, acetate totals
  - nutritional_summary: Protein energy, dextrose energy, lipid energy, nitrogen, non-protein energy,
    total energy, total kcal per nitrogen, protein energy per nitrogen, non-protein energy per nitrogen,
    protein to non-protein ratio, lipid to total energy ratio
  - calculated_at: Timestamp
  """
  def calculate_order_values(order_attrs, template, products_data) do
    %{}
    |> calculate_infusion_rates(order_attrs, template)
    |> calculate_nutritional_values(order_attrs, products_data, template)
    |> calculate_electrolyte_totals(products_data)
    |> calculate_nutritional_summary(products_data)
    |> add_metadata()
  end

  defp calculate_infusion_rates(acc, order_attrs, template) do
    bag_volume = D.new(template.fluids || 0)
    overfill_volume = D.new(template.bag_over_fill_volume || 0)
    total_volume = D.add(bag_volume, overfill_volume)

    tpn_duration = D.new(order_attrs[:tpn_infusion_duration_hours] || 24)
    lipid_duration = D.new(order_attrs[:lipid_infusion_duration_hours] || 24)

    # Calculate rates
    tpn_rate = if D.eq?(tpn_duration, 0), do: D.new(0), else: D.div(total_volume, tpn_duration)

    lipid_rate =
      if D.eq?(lipid_duration, 0), do: D.new(0), else: D.div(total_volume, lipid_duration)

    # Total fluids (including any custom fluids from template_fluids)
    template_fluids = Map.get(order_attrs, :template_fluids, %{})
    custom_fluids = D.new(Map.get(template_fluids, "custom", 0) || 0)
    total_fluids = D.add(total_volume, custom_fluids)

    infusion_calculations = %{
      tpn_rate: D.to_float(tpn_rate),
      lipid_rate: D.to_float(lipid_rate),
      total_fluids: D.to_float(total_fluids),
      custom_tpn_rate: D.to_float(custom_fluids)
    }

    Map.put(acc, :infusion_calculations, infusion_calculations)
  end

  defp calculate_nutritional_values(acc, order_attrs, products_data, template) do
    dosing_weight_str = order_attrs[:dosing_weight] || "0"
    dosing_weight = parse_dosing_weight(dosing_weight_str)

    tpn_duration = D.new(order_attrs[:tpn_infusion_duration_hours] || 24)
    lipid_duration = D.new(order_attrs[:lipid_infusion_duration_hours] || 24)

    # Find key products
    amino_acid_product = find_product_by_class(products_data, ["amino", "acid", "protein"])

    dextrose_product =
      find_product_by_class(products_data, ["dextrose", "glucose", "carbohydrate"])

    lipid_product = find_product_by_class(products_data, ["lipid", "fat", "lipids"])

    # Calculate GIR (Glucose Infusion Rate)
    gir = calculate_gir(dextrose_product, dosing_weight, tpn_duration)

    # Calculate percentages
    amino_acid_percent = calculate_amino_acid_percent(amino_acid_product, products_data)
    dextrose_percent = calculate_dextrose_percent(dextrose_product, products_data)

    # Calculate fat infusion rate
    fat_infusion_rate = calculate_fat_infusion_rate(lipid_product, dosing_weight, lipid_duration)

    # Calculate osmolarity
    osmolarity = calculate_osmolarity(products_data, template)

    nutritional_calculations = %{
      gir: D.to_float(gir),
      amino_acid_percent: D.to_float(amino_acid_percent),
      dextrose_percent: D.to_float(dextrose_percent),
      fat_infusion_rate: D.to_float(fat_infusion_rate),
      osmolarity: D.to_float(osmolarity)
    }

    Map.put(acc, :nutritional_calculations, nutritional_calculations)
  end

  defp calculate_electrolyte_totals(acc, products_data) do
    initial_totals = %{
      sodium: D.new(0),
      potassium: D.new(0),
      calcium: D.new(0),
      magnesium: D.new(0),
      phosphate: D.new(0),
      chloride: D.new(0),
      acetate: D.new(0)
    }

    totals =
      Enum.reduce(products_data, initial_totals, fn product, acc_totals ->
        electrolyte_contributions = Map.get(product, :electrolyte_contributions, %{})

        Enum.reduce(electrolyte_contributions, acc_totals, fn {electrolyte, amount}, acc_inner ->
          current = Map.get(acc_inner, String.to_atom(electrolyte), D.new(0))
          amount_decimal = D.new(amount || 0)
          Map.put(acc_inner, String.to_atom(electrolyte), D.add(current, amount_decimal))
        end)
      end)

    # Convert to float values for storage
    electrolyte_summary = Map.new(totals, fn {key, value} -> {key, D.to_float(value)} end)

    Map.put(acc, :electrolyte_summary, electrolyte_summary)
  end

  defp calculate_nutritional_summary(acc, products_data) do
    # Find key products
    amino_acid_product = find_product_by_class(products_data, ["amino", "acid", "protein"])

    dextrose_product =
      find_product_by_class(products_data, ["dextrose", "glucose", "carbohydrate"])

    lipid_product = find_product_by_class(products_data, ["lipid", "fat", "lipids"])

    # Calculate energy values (kcal)
    protein_energy = calculate_protein_energy(amino_acid_product)
    dextrose_energy = calculate_dextrose_energy(dextrose_product)
    lipid_energy = calculate_lipid_energy(lipid_product)

    # Calculate nitrogen (g)
    nitrogen = calculate_nitrogen(amino_acid_product)

    # Calculate derived values
    non_protein_energy = D.add(dextrose_energy, lipid_energy)
    total_energy = D.add(protein_energy, non_protein_energy)

    # Calculate ratios
    total_kcal_per_nitrogen =
      if D.eq?(nitrogen, 0), do: D.new(0), else: D.div(total_energy, nitrogen)

    protein_energy_per_nitrogen =
      if D.eq?(nitrogen, 0), do: D.new(0), else: D.div(protein_energy, nitrogen)

    non_protein_energy_per_nitrogen =
      if D.eq?(nitrogen, 0), do: D.new(0), else: D.div(non_protein_energy, nitrogen)

    protein_to_non_protein_ratio =
      if D.eq?(non_protein_energy, 0),
        do: D.new(0),
        else: D.div(protein_energy, non_protein_energy)

    lipid_to_total_energy_ratio =
      if D.eq?(total_energy, 0), do: D.new(0), else: D.div(lipid_energy, total_energy)

    nutritional_summary = %{
      protein_energy: D.to_float(protein_energy),
      dextrose_energy: D.to_float(dextrose_energy),
      lipid_energy: D.to_float(lipid_energy),
      nitrogen: D.to_float(nitrogen),
      non_protein_energy: D.to_float(non_protein_energy),
      total_energy: D.to_float(total_energy),
      total_kcal_per_nitrogen: D.to_float(total_kcal_per_nitrogen),
      protein_energy_per_nitrogen: D.to_float(protein_energy_per_nitrogen),
      non_protein_energy_per_nitrogen: D.to_float(non_protein_energy_per_nitrogen),
      protein_to_non_protein_ratio: D.to_float(protein_to_non_protein_ratio),
      lipid_to_total_energy_ratio: D.to_float(lipid_to_total_energy_ratio)
    }

    Map.put(acc, :nutritional_summary, nutritional_summary)
  end

  defp calculate_total_osmoles(products_data) do
    OsmolarityValidation.calculate_total_osmoles(products_data)
  end

  defp find_product_by_class(products_data, class_keywords) do
    Enum.find(products_data, fn product ->
      class_name = String.downcase(product.class_name || "")

      Enum.any?(class_keywords, fn keyword ->
        String.contains?(class_name, keyword)
      end)
    end)
  end

  # Helper functions for nutritional calculations

  defp parse_dosing_weight(dosing_weight_str) do
    case Float.parse(dosing_weight_str) do
      {weight, _} -> D.new(weight)
      :error -> D.new(0)
    end
  end

  defp calculate_gir(nil, _dosing_weight, _duration), do: D.new(0)

  defp calculate_gir(dextrose_product, dosing_weight, duration) do
    dose_mg = D.new(dextrose_product.dose || 0)

    if D.eq?(dosing_weight, 0) or D.eq?(duration, 0) do
      D.new(0)
    else
      # GIR = (dose_mg / dosing_weight) / duration
      D.div(dose_mg, dosing_weight)
      |> D.div(duration)
    end
  end

  defp calculate_amino_acid_percent(nil, _products_data), do: D.new(0)

  defp calculate_amino_acid_percent(amino_acid_product, products_data) do
    total_volume = calculate_total_volume(products_data)
    amino_volume = D.new(amino_acid_product.volume || 0)

    if D.eq?(total_volume, 0) do
      D.new(0)
    else
      D.mult(D.div(amino_volume, total_volume), D.new(100))
    end
  end

  defp calculate_dextrose_percent(nil, _products_data), do: D.new(0)

  defp calculate_dextrose_percent(dextrose_product, products_data) do
    total_volume = calculate_total_volume(products_data)
    dextrose_volume = D.new(dextrose_product.volume || 0)

    if D.eq?(total_volume, 0) do
      D.new(0)
    else
      D.mult(D.div(dextrose_volume, total_volume), D.new(100))
    end
  end

  defp calculate_fat_infusion_rate(nil, _dosing_weight, _duration), do: D.new(0)

  defp calculate_fat_infusion_rate(lipid_product, dosing_weight, duration) do
    lipid_dose = D.new(lipid_product.dose || 0)

    if D.eq?(dosing_weight, 0) or D.eq?(duration, 0) do
      D.new(0)
    else
      # Fat infusion rate = lipid_dose / (dosing_weight * duration)
      D.div(lipid_dose, D.mult(dosing_weight, duration))
    end
  end

  defp calculate_osmolarity(products_data, _template) do
    total_osmoles = calculate_total_osmoles(products_data)
    total_volume = calculate_total_volume(products_data)

    OsmolarityValidation.calculate_osmolarity(total_osmoles, total_volume)
  end

  defp calculate_total_volume(products_data) do
    Enum.reduce(products_data, D.new(0), fn product, acc ->
      volume = D.new(product.volume || 0)
      D.add(acc, volume)
    end)
  end

  defp calculate_protein_energy(nil), do: D.new(0)

  defp calculate_protein_energy(amino_acid_product) do
    # Protein energy = amino acid dose (g) * 4 kcal/g
    dose_g = D.new(amino_acid_product.dose || 0)
    D.mult(dose_g, D.new(4))
  end

  defp calculate_dextrose_energy(nil), do: D.new(0)

  defp calculate_dextrose_energy(dextrose_product) do
    # Dextrose energy = dextrose dose (g) * 3.4 kcal/g
    dose_g = D.new(dextrose_product.dose || 0)
    D.mult(dose_g, D.new(3.4))
  end

  defp calculate_lipid_energy(nil), do: D.new(0)

  defp calculate_lipid_energy(lipid_product) do
    # Lipid energy = lipid dose (g) * 9 kcal/g
    dose_g = D.new(lipid_product.dose || 0)
    D.mult(dose_g, D.new(9))
  end

  defp calculate_nitrogen(nil), do: D.new(0)

  defp calculate_nitrogen(amino_acid_product) do
    # Nitrogen = amino acid dose (g) * 0.16 (16% nitrogen in protein)
    dose_g = D.new(amino_acid_product.dose || 0)
    D.mult(dose_g, D.new(0.16))
  end

  defp add_metadata(acc) do
    Map.put(acc, :calculated_at, DateTime.utc_now())
  end
end
