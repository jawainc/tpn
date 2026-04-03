# TPN Order Form Calculations Strategy

## Overview
This document outlines the strategy for modifying the TPN order form to implement comprehensive calculations based on the CSV specification. The calculations will be performed in Alpine.js on the UI with backend support for data persistence and validation.

## CSV Analysis Summary

The CSV file contains comprehensive calculations for TPN orders including:

### 1. Basic Order Information
- Order type, bag ID, admission number, order date
- TPN infusion type, number of bags, vascular access
- Template selection, infusion duration type

### 2. Infusion Calculations
- TPN Rate: `Bag Volume / TPN Infusion Duration`
- Lipid Volume: `Lipid dose / product concentration` (with unit conversion)
- Lipid Rate: `Lipid volume / duration`
- Custom TPN rate (for premixed bags)
- Total Fluids: `(TPN Rate * Duration) + (Lipid rate * duration) + Enteral Product Dose`

### 3. Nutritional Calculations
- GIR (mg/kg/min): `(Dextrose dose in mg / Dosing weight) / (Duration in hours * 60)`
- Amino Acid %: `(Amino acid dose in gm / bag volume in mL) * 100`
- Dextrose %: `(Dextrose dose in g / bag volume in mL) * 100`
- Fat Infusion Rate (g/kg/hour): `(Lipid dose in g / dosing weight in kg) / lipid infusion duration`
- Osmolarity (mOsm/L): Sum of `(Substances volume * osmolarity from formulary) / (bag volume in mL/1000)`

### 4. Electrolyte Summary
- Total Sodium, Potassium, Calcium, Magnesium, Phosphate, Chloride, Acetate
- Calculated as: Sum of `(Substances volume * ingredient concentration in mmol/mL)` for each electrolyte

### 5. Nutritional Information Summary
- Protein Energy (Kcal): `Amino acid dose * 4`
- Dextrose Energy (Kcal): `Dextrose dose * 3.4`
- Lipid Energy (Kcal): `Lipid dose * 9`
- Nitrogen: `Amino acid dose / 6.25`
- Non-Protein Energy: `Dextrose energy + Lipid Energy`
- Total Energy: `Protein Energy + Dextrose energy + Lipid Energy`
- Various ratios and percentages

### 6. Child Table Calculations
- Calculated Volume: `(dose / product concentration) + (additional dose / product concentration)`
- Fill Volume: `(Calculated volume / bag volume) * (bag volume + overfill from template)`
- Unit conversion for concentration metrics

## Current Implementation Analysis

### Frontend Architecture
- **Alpine.js**: Used for UI interactions in `xData.js`
- **Components**:
  - `orderForm`: Basic form state management
  - `orderTemplateProducts`: Template products and calculations
- **HTMX**: Used for server communication and dynamic content loading

### Backend Architecture
- **Phoenix/Elixir**: Backend framework
- **Ecto Schemas**:
  - `Order`: Order management with basic fields
  - `Template`: Template configuration with fluids, overfill volumes
  - `Formulary`: Product information with concentration, calories, osmolarity
  - `FormularyIngredient`: Ingredient concentrations for electrolytes
  - `Ingredient`: Basic ingredient information

### Form Structure
1. **Order Form** (`order_form_new.html.heex`):
   - Basic order information
   - Template selection with HTMX loading
2. **Template Products** (`template_products.html.heex`):
   - Substances table with products
   - Basic volume calculations
   - Some calculation fields (GIR, amino acid %, etc.) but not fully implemented

## Implementation Strategy

### Phase 1: Data Model Enhancement

#### Extend Order Schema (`lib/tpn/hospital/order.ex`)
Add map fields for calculated values instead of individual fields to maintain flexibility:
```elixir
field :template_fluids, :map, default: %{}
field :template_properties, :map, default: %{}
field :order_calculations, :map, default: %{}  # NEW: Store all calculated values
field :order_products, :map, default: %{}      # NEW: Store order-specific product data
field :osmolarity_alerts, :map, default: %{}   # NEW: Store osmolarity alert information
field :osmolarity_comments, :text             # NEW: Store user comments for soft alerts
```

The `order_calculations` map will store:
```elixir
%{
  "infusion_calculations" => %{
    "tpn_rate" => decimal,
    "lipid_rate" => decimal,
    "total_fluids" => decimal,
    "custom_tpn_rate" => decimal
  },
  "nutritional_calculations" => %{
    "gir" => decimal,
    "amino_acid_percent" => decimal,
    "dextrose_percent" => decimal,
    "fat_infusion_rate" => decimal,
    "osmolarity" => decimal
  },
  "electrolyte_summary" => %{
    "total_sodium" => decimal,
    "total_potassium" => decimal,
    "total_calcium" => decimal,
    "total_magnesium" => decimal,
    "total_phosphate" => decimal,
    "total_chloride" => decimal,
    "total_acetate" => decimal
  },
  "nutritional_summary" => %{
    "protein_energy" => decimal,
    "dextrose_energy" => decimal,
    "lipid_energy" => decimal,
    "nitrogen" => decimal,
    "non_protein_energy" => decimal,
    "total_energy" => decimal,
    "total_kcal_per_nitrogen" => decimal,
    "protein_energy_per_nitrogen" => decimal,
    "non_protein_energy_per_nitrogen" => decimal,
    "protein_to_non_protein_ratio" => decimal,
    "lipid_to_total_energy_ratio" => decimal
  }
}
```

The `osmolarity_alerts` map will store osmolarity validation information:
```elixir
%{
  "limit" => decimal,           # Osmolarity limit from osmolarities table
  "calculated" => decimal,      # Calculated total osmolarity
  "exceeds_limit" => boolean,   # Whether calculated exceeds limit
  "alert_type" => "Soft" | "Hard", # Type of alert from osmolarities table
  "patient_type_id" => integer, # Patient type for reference
  "vascular_access_id" => integer, # Vascular access for reference
  "checked_at" => datetime,     # When validation was performed
  "override" => %{              # If user overrides soft alert
    "user_id" => integer,
    "comments" => string,
    "overridden_at" => datetime
  }
}
```

The `order_products` map will store order-specific product data with positions:
```elixir
%{
  "products" => [
    %{
      "id" => integer,           # Template product ID
      "position" => integer,     # User-adjusted position
      "class_id" => integer,
      "class_name" => string,
      "dose" => decimal,
      "dose_unit" => string,
      "formulary_id" => integer,
      "formulary_name" => string,
      "filling_method_id" => integer,
      "filling_method_name" => string,
      "volume" => decimal,       # Calculated: dose / concentration
      "fill_volume" => decimal,  # Calculated: (volume / bag_volume) * (bag_volume + overfill)
      "additional_dose" => decimal,
      "additional_dose_unit" => string,
      "max_allowed_limit" => decimal,
      "max_allowed_unit" => string,
      "substance_locked_on_order" => boolean,
      "calculated_values" => %{
        "concentration" => decimal,
        "osmolarity" => decimal,
        "ingredients" => [       # For electrolyte calculations
          %{"name" => "Sodium", "amount" => decimal, "unit" => string},
          %{"name" => "Potassium", "amount" => decimal, "unit" => string},
          # ... other ingredients
        ]
      }
    }
  ],
  "sort_order" => [id1, id2, id3, ...],  # Array of product IDs in display order
  "metadata" => %{
    "template_id" => integer,
    "template_name" => string,
    "bag_volume" => decimal,
    "overfill_volume" => decimal,
    "last_calculated_at" => datetime
  }
}
```

#### Create OrderProduct Schema (`lib/tpn/hospital/order_product.ex`)
For a more robust solution, consider creating a separate OrderProduct schema:
```elixir
defmodule Tpn.OrderProduct do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_products" do
    field :position, :integer
    field :dose, :decimal
    field :additional_dose, :decimal
    field :max_allowed_limit, :decimal
    field :volume, :decimal
    field :fill_volume, :decimal
    field :calculated_values, :map, default: %{}
    
    belongs_to :order, Tpn.Order
    belongs_to :template_product, Tpn.TemplateProduct
    belongs_to :formulary, Tpn.Formulary
    belongs_to :filling_method, Tpn.FillingMethod
    
    timestamps(type: :utc_datetime)
  end
end
```

#### Extend Template Schema (`lib/tpn/lab/template.ex`)
Ensure all necessary fields are available:
- `fluids` (bag volume)
- `fluid_unit_id` (units for bag volume)
- `bag_over_fill_volume` (for fill volume calculations)
- `lipid_over_fill_volume` (for lipid-specific overfill)

#### Create Osmolarity Validation Service (`lib/tpn/calculations/osmolarity_validation.ex`)
```elixir
defmodule Tpn.Calculations.OsmolarityValidation do
  alias Tpn.{Repo, Lab.Osmolarity}
  import Ecto.Query, warn: false
  
  @doc """
  Get osmolarity limit for a specific patient type and vascular access.
  Returns {:ok, osmolarity_record} or {:error, :not_found}
  """
  def get_osmolarity_limit(patient_type_id, vascular_access_id) do
    query = 
      from o in Osmolarity,
      where: o.patient_type_id == ^patient_type_id,
      where: o.vascular_access_id == ^vascular_access_id,
      limit: 1
    
    case Repo.one(query) do
      nil -> {:error, :not_found}
      osmolarity -> {:ok, osmolarity}
    end
  end
  
  @doc """
  Validate calculated osmolarity against limit.
  Returns validation result map.
  """
  def validate_osmolarity(calculated_osmolarity, osmolarity_limit_record) do
    limit = osmolarity_limit_record.osmolarity
    exceeds = Decimal.compare(calculated_osmolarity, limit) == :gt
    
    %{
      limit: limit,
      calculated: calculated_osmolarity,
      exceeds_limit: exceeds,
      alert_type: osmolarity_limit_record.alert_type,
      patient_type_id: osmolarity_limit_record.patient_type_id,
      vascular_access_id: osmolarity_limit_record.vascular_access_id,
      checked_at: DateTime.utc_now()
    }
  end
  
  @doc """
  Check if order can proceed based on osmolarity alert.
  Returns {:ok, :proceed} or {:error, :hard_alert} or {:warning, :soft_alert}
  """
  def can_proceed_with_order(alert_result, has_comments \\ false) do
    case alert_result do
      %{exceeds_limit: false} ->
        {:ok, :proceed}
      
      %{exceeds_limit: true, alert_type: "Hard"} ->
        {:error, :hard_alert}
      
      %{exceeds_limit: true, alert_type: "Soft", override: %{comments: comments}} 
        when is_binary(comments) and String.trim(comments) != "" ->
        {:ok, :proceed_with_override}
      
      %{exceeds_limit: true, alert_type: "Soft"} ->
        {:warning, :soft_alert_requires_comments}
    end
  end
  
  @doc """
  Create an API endpoint to get osmolarity limit by patient type and vascular access.
  """
  def get_osmolarity_limit_api(patient_type_id, vascular_access_id) do
    case get_osmolarity_limit(patient_type_id, vascular_access_id) do
      {:ok, osmolarity} ->
        {:ok, %{
          id: osmolarity.id,
          name: osmolarity.name,
          osmolarity: osmolarity.osmolarity,
          alert_type: osmolarity.alert_type,
          unit_id: osmolarity.unit_id,
          patient_type_id: osmolarity.patient_type_id,
          vascular_access_id: osmolarity.vascular_access_id
        }}
      
      {:error, :not_found} ->
        {:error, :not_found, "No osmolarity limit found for patient type #{patient_type_id} and vascular access #{vascular_access_id}"}
    end
  end
end
```

#### Update Order Status Workflow Preservation
When order status changes (draft → pending → approved → rejected), we need to preserve:
1. **Original calculated values** at the time of submission
2. **Product selections and positions** as they were when submitted
3. **Audit trail** of changes for each status transition

Add to Order schema:
```elixir
field :calculation_snapshots, :map, default: %{}  # Store calculations at each status change
field :product_snapshots, :map, default: %{}      # Store product data at each status change
```

Example structure:
```elixir
%{
  "draft" => %{
    "calculated_at" => datetime,
    "calculations" => %{...},
    "products" => %{...}
  },
  "pending" => %{
    "calculated_at" => datetime,
    "calculations" => %{...},
    "products" => %{...}
  },
  "approved" => %{
    "calculated_at" => datetime,
    "calculations" => %{...},
    "products" => %{...}
  }
}
```

### Phase 2: Alpine.js Calculation Engine

#### Create Comprehensive Calculation Module (`assets/js/tpn-calculations.js`)
```javascript
window.tpnCalculations = {
  // Basic infusion calculations
  calculateTPNRate(bagVolume, duration) {
    return bagVolume / duration;
  },
  
  calculateLipidVolume(lipidDose, concentration, unitConversion = 1) {
    return (lipidDose / concentration) * unitConversion;
  },
  
  calculateLipidRate(lipidVolume, duration) {
    return lipidVolume / duration;
  },
  
  calculateTotalFluids(tpnRate, tpnDuration, lipidRate, lipidDuration, enteralDose) {
    return (tpnRate * tpnDuration) + (lipidRate * lipidDuration) + enteralDose;
  },
  
  // Nutritional calculations
  calculateGIR(dextroseDoseMg, dosingWeightKg, durationHours) {
    return (dextroseDoseMg / dosingWeightKg) / (durationHours * 60);
  },
  
  calculateAminoAcidPercent(aminoAcidDoseG, bagVolumeMl) {
    return (aminoAcidDoseG / bagVolumeMl) * 100;
  },
  
  calculateDextrosePercent(dextroseDoseG, bagVolumeMl) {
    return (dextroseDoseG / bagVolumeMl) * 100;
  },
  
  calculateFatInfusionRate(lipidDoseG, dosingWeightKg, lipidDurationHours) {
    return (lipidDoseG / dosingWeightKg) / lipidDurationHours;
  },
  
  calculateOsmolarity(substances, bagVolumeMl) {
    // substances: array of {volume, osmolarity}
    const totalOsmoles = substances.reduce((sum, substance) => {
      return sum + (substance.volume * substance.osmolarity);
    }, 0);
    return totalOsmoles / (bagVolumeMl / 1000);
  },
  
  // Osmolarity validation functions
  async fetchOsmolarityLimit(patientTypeId, vascularAccessId) {
    try {
      const response = await fetch(`/api/osmolarities/limit?patient_type_id=${patientTypeId}&vascular_access_id=${vascularAccessId}`);
      if (response.ok) {
        return await response.json();
      }
      return null;
    } catch (error) {
      console.error('Error fetching osmolarity limit:', error);
      return null;
    }
  },
  
  validateAgainstLimit(calculatedOsmolarity, limitRecord) {
    if (!limitRecord) return null;
    
    const exceeds = calculatedOsmolarity > limitRecord.osmolarity;
    
    return {
      limit: limitRecord.osmolarity,
      calculated: calculatedOsmolarity,
      exceeds_limit: exceeds,
      alert_type: limitRecord.alert_type,
      patient_type_id: limitRecord.patient_type_id,
      vascular_access_id: limitRecord.vascular_access_id,
      checked_at: new Date().toISOString()
    };
  },
  
  canProceedWithOrder(alertResult, hasComments = false) {
    if (!alertResult || !alertResult.exceeds_limit) {
      return { canProceed: true, type: 'ok', message: 'Osmolarity within limits' };
    }
    
    if (alertResult.alert_type === 'Hard') {
      return { 
        canProceed: false, 
        type: 'error', 
        message: `Hard alert: Osmolarity (${alertResult.calculated.toFixed(0)} mOsm/L) exceeds limit (${alertResult.limit} mOsm/L) for this patient type and vascular access` 
      };
    }
    
    if (alertResult.alert_type === 'Soft' && hasComments) {
      return { 
        canProceed: true, 
        type: 'warning_override', 
        message: `Soft alert overridden with comments: Osmolarity (${alertResult.calculated.toFixed(0)} mOsm/L) exceeds limit (${alertResult.limit} mOsm/L)` 
      };
    }
    
    if (alertResult.alert_type === 'Soft') {
      return { 
        canProceed: false, 
        type: 'warning', 
        message: `Soft alert: Osmolarity (${alertResult.calculated.toFixed(0)} mOsm/L) exceeds limit (${alertResult.limit} mOsm/L). Please add comments to proceed.` 
      };
    }
    
    return { canProceed: true, type: 'ok', message: 'No osmolarity validation performed' };
  },
  
  // Electrolyte calculations
  calculateElectrolyteTotal(substances, electrolyteName) {
    return substances.reduce((total, substance) => {
      const electrolyte = substance.ingredients?.find(i => i.name === electrolyteName);
      return total + (substance.volume * (electrolyte?.concentration || 0));
    }, 0);
  },
  
  // Nutritional summary calculations
  calculateProteinEnergy(aminoAcidDose) {
    return aminoAcidDose * 4;
  },
  
  calculateDextroseEnergy(dextroseDose) {
    return dextroseDose * 3.4;
  },
  
  calculateLipidEnergy(lipidDose) {
    return lipidDose * 9;
  },
  
  calculateNitrogen(aminoAcidDose) {
    return aminoAcidDose / 6.25;
  },
  
  // Product-specific calculations
  calculateProductVolume(dose, concentration, unitConversion = 1) {
    return (dose / concentration) * unitConversion;
  },
  
  calculateFillVolume(productVolume, bagVolume, overfillVolume) {
    return (productVolume / bagVolume) * (bagVolume + overfillVolume);
  },
  
  // Unit conversion helpers
  convertUnits(value, fromUnit, toUnit, conversionFactors) {
    const factor = conversionFactors[`${fromUnit}_to_${toUnit}`];
    return factor ? value * factor : value;
  },
  
  // Validation functions
  validateCustomTPNRate(customRate, duration, bagVolume) {
    return customRate * duration <= bagVolume;
  },
  
  validateTotalFluids(totalFluids, templateFluids) {
    return totalFluids <= templateFluids;
  },
  
  // Osmolarity alert serialization
  serializeOsmolarityAlert(alertResult, overrideComments = null, userId = null) {
    if (!alertResult) return null;
    
    const result = { ...alertResult };
    
    if (overrideComments && userId) {
      result.override = {
        user_id: userId,
        comments: overrideComments,
        overridden_at: new Date().toISOString()
      };
    }
    
    return result;
  },
  
  // Data serialization for backend
  serializeOrderProducts(productsData, sortOrder) {
    return {
      products: productsData.map(product => ({
        id: product.id,
        position: product.position,
        class_id: product.class_id,
        class_name: product.class_name,
        dose: product.dose,
        dose_unit: product.dose_unit,
        formulary_id: product.formulary_id,
        formulary_name: product.formulary_name,
        filling_method_id: product.filling_method_id,
        filling_method_name: product.filling_method?.name,
        volume: product.volume,
        fill_volume: product.fill_volume,
        additional_dose: product.additional_dose,
        additional_dose_unit: product.additional_dose_unit,
        max_allowed_limit: product.max_allowed_limit,
        max_allowed_unit: product.max_allowed_unit,
        substance_locked_on_order: product.substance_locked_on_order
      })),
      sort_order: sortOrder || productsData.map(p => p.id),
      metadata: {
        calculated_at: new Date().toISOString()
      }
    };
  },
  
  // Data deserialization from backend
  deserializeOrderProducts(orderProductsData) {
    if (!orderProductsData || !orderProductsData.products) return [];
    
    // Sort products according to stored sort_order
    const sortedProducts = [...orderProductsData.products];
    if (orderProductsData.sort_order) {
      sortedProducts.sort((a, b) => {
        const indexA = orderProductsData.sort_order.indexOf(a.id);
        const indexB = orderProductsData.sort_order.indexOf(b.id);
        return indexA - indexB;
      });
    }
    
    return sortedProducts;
  }
};
```


            
#### Enhance `orderTemplateProducts` Component (`assets/js/xData.js`)
Add reactive calculations, product sorting, and data preservation:
```javascript
window.orderTemplateProducts = function() {
  return {
    // ... existing properties ...
    
    // New properties for calculations and sorting
    calculations: {
      infusion: {
        tpnRate: 0,
        lipidRate: 0,
        totalFluids: 0,
        customTpnRate: 0
      },
      nutritional: {
        gir: 0,
        aminoAcidPercent: 0,
        dextrosePercent: 0,
        fatInfusionRate: 0,
        osmolarity: 0
      },
    },
    
    // Osmolarity alert state
    osmolarityAlert: null,
    osmolarityLimit: null,
    osmolarityComments: '',
    showOsmolarityAlertModal: false,
      electrolyteTotals: {
        sodium: 0,
        potassium: 0,
        calcium: 0,
        magnesium: 0,
        phosphate: 0,
        chloride: 0,
        acetate: 0
      },
      nutritionalSummary: {
        proteinEnergy: 0,
        dextroseEnergy: 0,
        lipidEnergy: 0,
        nitrogen: 0,
        nonProteinEnergy: 0,
        totalEnergy: 0,
        totalKcalPerNitrogen: 0,
        proteinEnergyPerNitrogen: 0,
        nonProteinEnergyPerNitrogen: 0,
        proteinToNonProteinRatio: 0,
        lipidToTotalEnergyRatio: 0
      }
    },
    
    // Product sorting state
    sortOrder: [],  // Array of product IDs in current display order
    isDragging: false,
    dragStartIndex: null,
    
    // New methods
    initSorting() {
      // Initialize sort order from template products or restored order
      if (this.productsData.length > 0) {
        this.sortOrder = this.productsData.map(p => p.id);
      }
    },
    
    handleDragStart(index) {
      this.isDragging = true;
      this.dragStartIndex = index;
    },
    
    handleDragOver(event, index) {
      event.preventDefault();
      if (!this.isDragging || this.dragStartIndex === index) return;
      
      // Reorder products
      const draggedProduct = this.productsData[this.dragStartIndex];
      this.productsData.splice(this.dragStartIndex, 1);
      this.productsData.splice(index, 0, draggedProduct);
      
      // Update sort order
      const draggedId = this.sortOrder[this.dragStartIndex];
      this.sortOrder.splice(this.dragStartIndex, 1);
      this.sortOrder.splice(index, 0, draggedId);
      
      this.dragStartIndex = index;
    },
    
    handleDragEnd() {
      this.isDragging = false;
      this.dragStartIndex = null;
      
      // Recalculate all values after reordering
      this.calculateAll();
    },
    
    calculateAll() {
      this.calculateSubstanceVolumes();
      this.calculateInfusionRates();
      this.calculateNutritionalValues();
      this.calculateElectrolyteTotals();
      this.calculateNutritionalSummary();
      
      // Update UI with calculated values
      this.updateCalculationDisplays();
    },
    
    calculateSubstanceVolumes() {
      const bagVolume = this.getBagVolume();
      const overfillVolume = this.getOverfillVolume();
      
      this.productsData.forEach(product => {
        if (product.formulary_id && product.dose) {
          const formulary = this.formularies.find(f => f.id === product.formulary_id);
          if (formulary && formulary.concentration) {
            // Calculate volume: dose / concentration (with unit conversion if needed)
            product.volume = product.dose / formulary.concentration;
            
            // Calculate fill volume: (volume / bag volume) * (bag volume + overfill)
            if (bagVolume > 0) {
              product.fill_volume = (product.volume / bagVolume) * (bagVolume + overfillVolume);
            } else {
              product.fill_volume = 0;
            }
            
            // Store formulary data for calculations
            product.calculated_values = {
              concentration: formulary.concentration,
              osmolarity: formulary.osmolarity || 0,
              ingredients: formulary.ingredients || []
            };
          }
        }
      });
    },
    
    calculateInfusionRates() {
      const bagVolume = this.getBagVolume();
      const tpnDuration = this.getTPNInfusionDuration();
      const lipidDuration = this.getLipidInfusionDuration();
      
      // TPN Rate = Bag Volume / TPN Infusion Duration
      this.calculations.infusion.tpnRate = tpnDuration > 0 ? bagVolume / tpnDuration : 0;
      
      // Calculate lipid rate if applicable
      const lipidProduct = this.getLipidProduct();
      if (lipidProduct && lipidDuration > 0) {
        const lipidVolume = this.calculateLipidVolume(lipidProduct);
        this.calculations.infusion.lipidRate = lipidVolume / lipidDuration;
      }
      
      // Total Fluids = (TPN Rate * Duration) + (Lipid Rate * Duration) + Enteral Dose
      this.calculations.infusion.totalFluids = this.calculateTotalFluids();
    },
    
    calculateNutritionalValues() {
      const bagVolume = this.getBagVolume();
      const dosingWeight = this.getDosingWeight();
      const tpnDuration = this.getTPNInfusionDuration();
      const lipidDuration = this.getLipidInfusionDuration();
      
      // Get amino acid and dextrose products
      const aminoAcidProduct = this.getAminoAcidProduct();
      const dextroseProduct = this.getDextroseProduct();
      const lipidProduct = this.getLipidProduct();
      
      // Calculate GIR: (Dextrose dose in mg / Dosing weight) / (Duration in hours * 60)
      if (dextroseProduct && dextroseProduct.dose && dosingWeight > 0 && tpnDuration > 0) {
        const dextroseDoseMg = dextroseProduct.dose * 1000; // Convert g to mg
        this.calculations.nutritional.gir = (dextroseDoseMg / dosingWeight) / (tpnDuration * 60);
      }
      
      // Calculate Amino Acid %: (Amino acid dose in gm / bag volume in mL) * 100
      if (aminoAcidProduct && aminoAcidProduct.dose && bagVolume > 0) {
        this.calculations.nutritional.aminoAcidPercent = (aminoAcidProduct.dose / bagVolume) * 100;
      }
      
      // Calculate Dextrose %: (Dextrose dose in g / bag volume in mL) * 100
      if (dextroseProduct && dextroseProduct.dose && bagVolume > 0) {
        this.calculations.nutritional.dextrosePercent = (dextroseProduct.dose / bagVolume) * 100;
      }
      
      // Calculate Fat Infusion Rate: (Lipid dose in g / dosing weight in kg) / lipid infusion duration
      if (lipidProduct && lipidProduct.dose && dosingWeight > 0 && lipidDuration > 0) {
        this.calculations.nutritional.fatInfusionRate = (lipidProduct.dose / dosingWeight) / lipidDuration;
      }
      
      // Calculate Osmolarity: Sum of (substances volume * osmolarity) / (bag volume in mL/1000)
      let totalOsmoles = 0;
      this.productsData.forEach(product => {
        if (product.volume && product.calculated_values?.osmolarity) {
          totalOsmoles += product.volume * product.calculated_values.osmolarity;
        }
      });
      this.calculations.nutritional.osmolarity = bagVolume > 0 ? totalOsmoles / (bagVolume / 1000) : 0;
      
      // Validate osmolarity against limit
      this.validateOsmolarity();
    },
    
    async validateOsmolarity() {
      const patientTypeId = this.getPatientTypeId();
      const vascularAccessId = this.getVascularAccessId();
      
      if (!patientTypeId || !vascularAccessId) return;
      
      // Fetch osmolarity limit for this patient type and vascular access
      this.osmolarityLimit = await window.tpnCalculations.fetchOsmolarityLimit(
        patientTypeId, 
        vascularAccessId
      );
      
      if (this.osmolarityLimit) {
        this.osmolarityAlert = window.tpnCalculations.validateAgainstLimit(
          this.calculations.nutritional.osmolarity,
          this.osmolarityLimit
        );
        
        // Show alert modal if exceeds limit
        if (this.osmolarityAlert?.exceeds_limit) {
          this.showOsmolarityAlertModal = true;
        }
      }
    },
    
    getPatientTypeId() {
      // Get patient type from admission data
      return this.admission?.patient_type_id;
    },
    
    getVascularAccessId() {
      // Get vascular access from form
      return document.querySelector('select[name="order[vascular_access_id]"]')?.value;
    },
    
    handleOsmolarityAlertOverride() {
      if (!this.osmolarityComments.trim()) {
        alert('Please enter comments to override the soft alert');
        return;
      }
      
      // Add override information to alert
      this.osmolarityAlert.override = {
        user_id: this.currentUserId,
        comments: this.osmolarityComments,
        overridden_at: new Date().toISOString()
      };
      
      this.showOsmolarityAlertModal = false;
      this.osmolarityComments = '';
    },
    
    handleOsmolarityAlertCancel() {
      // Reset form values that caused high osmolarity
      this.resetHighOsmolarityValues();
      this.showOsmolarityAlertModal = false;
      this.osmolarityComments = '';
    },
    
    resetHighOsmolarityValues() {
      // Find products contributing most to osmolarity and reset their doses
      const productsByOsmolarity = [...this.productsData]
        .map(product => ({
          ...product,
          osmolarityContribution: (product.volume || 0) * (product.calculated_values?.osmolarity || 0)
        }))
        .sort((a, b) => b.osmolarityContribution - a.osmolarityContribution);
      
      // Reset top 3 contributors
      productsByOsmolarity.slice(0, 3).forEach(product => {
        product.dose = 0;
      });
      
      // Recalculate
      this.calculateAll();
    },
    
    calculateElectrolyteTotals() {
      // Reset all electrolyte totals
      Object.keys(this.calculations.electrolyteTotals).forEach(key => {
        this.calculations.electrolyteTotals[key] = 0;
      });
      
      // Calculate electrolyte totals from product ingredients
      this.productsData.forEach(product => {
        if (product.volume && product.calculated_values?.ingredients) {
          product.calculated_values.ingredients.forEach(ingredient => {
            const electrolyteName = ingredient.name.toLowerCase();
            if (this.calculations.electrolyteTotals.hasOwnProperty(electrolyteName)) {
              // Add: substance volume * ingredient concentration
              this.calculations.electrolyteTotals[electrolyteName] += 
                product.volume * ingredient.amount;
            }
          });
        }
      });
    },
    
    calculateNutritionalSummary() {
      const aminoAcidProduct = this.getAminoAcidProduct();
      const dextroseProduct = this.getDextroseProduct();
      const lipidProduct = this.getLipidProduct();
      
      // Protein Energy = Amino acid dose * 4
      const proteinEnergy = aminoAcidProduct?.dose ? aminoAcidProduct.dose * 4 : 0;
      this.calculations.nutritionalSummary.proteinEnergy = proteinEnergy;
      
      // Dextrose Energy = Dextrose dose * 3.4
      const dextroseEnergy = dextroseProduct?.dose ? dextroseProduct.dose * 3.4 : 0;
      this.calculations.nutritionalSummary.dextroseEnergy = dextroseEnergy;
      
      // Lipid Energy = Lipid dose * 9
      const lipidEnergy = lipidProduct?.dose ? lipidProduct.dose * 9 : 0;
      this.calculations.nutritionalSummary.lipidEnergy = lipidEnergy;
      
      // Nitrogen = Amino acid dose / 6.25
      this.calculations.nutritionalSummary.nitrogen = aminoAcidProduct?.dose ? 
        aminoAcidProduct.dose / 6.25 : 0;
      
      // Non-Protein Energy = Dextrose Energy + Lipid Energy
      const nonProteinEnergy = dextroseEnergy + lipidEnergy;
      this.calculations.nutritionalSummary.nonProteinEnergy = nonProteinEnergy;
      
      // Total Energy = Protein Energy + Dextrose Energy + Lipid Energy
      const totalEnergy = proteinEnergy + dextroseEnergy + lipidEnergy;
      this.calculations.nutritionalSummary.totalEnergy = totalEnergy;
      
      // Calculate ratios (avoid division by zero)
      const nitrogen = this.calculations.nutritionalSummary.nitrogen;
      if (nitrogen > 0) {
        this.calculations.nutritionalSummary.totalKcalPerNitrogen = totalEnergy / nitrogen;
        this.calculations.nutritionalSummary.proteinEnergyPerNitrogen = proteinEnergy / nitrogen;
        this.calculations.nutritionalSummary.nonProteinEnergyPerNitrogen = nonProteinEnergy / nitrogen;
      }
      
      if (nonProteinEnergy > 0) {
        this.calculations.nutritionalSummary.proteinToNonProteinRatio = proteinEnergy / nonProteinEnergy;
      }
      
      if (totalEnergy > 0) {
        this.calculations.nutritionalSummary.lipidToTotalEnergyRatio = lipidEnergy / totalEnergy;
      }
    },
    
    updateCalculationDisplays() {
      // Update all readonly input fields with calculated values
      this.updateInputField('template_tpn_rate', this.calculations.infusion.tpnRate);
      this.updateInputField('template_lipid_rate', this.calculations.infusion.lipidRate);
      this.updateInputField('template_gir', this.calculations.nutritional.gir);
      this.updateInputField('template_amino_acid', this.calculations.nutritional.aminoAcidPercent);
      this.updateInputField('template_dextrose', this.calculations.nutritional.dextrosePercent);
      this.updateInputField('template_fat_infusion_rate', this.calculations.nutritional.fatInfusionRate);
      this.updateInputField('template_osmolarity', this.calculations.nutritional.osmolarity);
    },
    
    updateInputField(fieldName, value) {
      const field = document.querySelector(`input[name="${fieldName}"]`);
      if (field) {
        field.value = value.toFixed(4);
      }
    },
    
    // Helper methods
    getBagVolume() {
      return parseFloat(document.querySelector('input[name="template_fluids"]')?.value || 0);
    },
    
    getOverfillVolume() {
      // Get from template data or default
      return this.template?.bag_over_fill_volume || 0;
    },
    
    getTPNInfusionDuration() {
      return parseFloat(document.querySelector('input[name="tpn_infusion_duration_hours"]')?.value || 24);
    },
    
    getLipidInfusionDuration() {
      return parseFloat(document.querySelector('input[name="lipid_infusion_duration_hours"]')?.value || 0);
    },
    
    getDosingWeight() {
      return parseFloat(document.querySelector('input[name="dosing_weight"]')?.value || 0);
    },
    
    getLipidProduct() {
      return this.productsData.find(p => 
        p.class_name?.toLowerCase().includes('lipid') || 
        p.class_name?.toLowerCase().includes('fat')
      );
    },
    
    getAminoAcidProduct() {
      return this.productsData.find(p => 
        p.class_name?.toLowerCase().includes('amino') || 
        p.class_name?.toLowerCase().includes('protein')
      );
    },
    
    getDextroseProduct() {
      return this.productsData.find(p => 
        p.class_name?.toLowerCase().includes('dextrose') || 
        p.class_name?.toLowerCase().includes('glucose')
      );
    },
    
    calculateLipidVolume(lipidProduct) {
      if (!lipidProduct?.dose || !lipidProduct?.formulary_id) return 0;
      
      const formulary = this.formularies.find(f => f.id === lipidProduct.formulary_id);
      if (!formulary?.concentration) return 0;
      
      return lipidProduct.dose / formulary.concentration;
    },
    
    calculateTotalFluids() {
      const tpnDuration = this.getTPNInfusionDuration();
      const lipidDuration = this.getLipidInfusionDuration();
      const enteralDose = parseFloat(document.querySelector('input[name="enteral_dose"]')?.value || 0);
      
      return (this.calculations.infusion.tpnRate * tpnDuration) + 
             (this.calculations.infusion.lipidRate * lipidDuration) + 
             enteralDose;
    },
    
    // Data serialization for order submission
    getOrderProductsData() {
      return window.tpnCalculations.serializeOrderProducts(this.productsData, this.sortOrder);
    },
    
    getOrderCalculationsData() {
      return {
        infusion_calculations: this.calculations.infusion,
        nutritional_calculations: this.calculations.nutritional,
        electrolyte_summary: this.calculations.electrolyteTotals,
        nutritional_summary: this.calculations.nutritionalSummary,
        calculated_at: new Date().toISOString()
      };
    },
    
    getOsmolarityAlertData() {
      return window.tpnCalculations.serializeOsmolarityAlert(
        this.osmolarityAlert,
        this.osmolarityComments,
        this.currentUserId
      );
    },
    
    // Load saved order data
    loadOrderData(orderData) {
      if (orderData.order_products) {
        const restoredProducts = window.tpnCalculations.deserializeOrderProducts(orderData.order_products);
        this.productsData = restoredProducts;
        this.sortOrder = orderData.order_products.sort_order || restoredProducts.map(p => p.id);
      }
      
      if (orderData.order_calculations) {
        this.calculations = {
          infusion: orderData.order_calculations.infusion_calculations || {},
          nutritional: orderData.order_calculations.nutritional_calculations || {},
          electrolyteTotals: orderData.order_calculations.electrolyte_summary || {},
          nutritionalSummary: orderData.order_calculations.nutritional_summary || {}
        };
      }
    }
  };
};
```

### Phase 3: UI Enhancements

#### Update Order Form Template (`order_form_new.html.heex`)
Add hidden fields to store calculated data and product order:
```html
<input type="hidden" name="order[order_calculations]" x-bind:value="JSON.stringify(getOrderCalculationsData())" />
<input type="hidden" name="order[order_products]" x-bind:value="JSON.stringify(getOrderProductsData())" />
<input type="hidden" name="order[calculation_snapshots]" x-bind:value="JSON.stringify(calculationSnapshots)" />
<input type="hidden" name="order[product_snapshots]" x-bind:value="JSON.stringify(productSnapshots)" />
<input type="hidden" name="order[osmolarity_alerts]" x-bind:value="JSON.stringify(getOsmolarityAlertData())" />
<input type="hidden" name="order[osmolarity_comments]" x-bind:value="osmolarityComments" />
```

#### Add Osmolarity Alert Modal
Add a modal for displaying and handling osmolarity alerts:
```html
<!-- Osmolarity Alert Modal -->
<dialog id="osmolarityAlertModal" class="modal" x-show="showOsmolarityAlertModal" @click.away="showOsmolarityAlertModal = false">
  <div class="modal-box" @click.stop>
    <h3 class="font-bold text-lg" x-text="osmolarityAlert?.alert_type === 'Hard' ? 'Hard Osmolarity Alert' : 'Soft Osmolarity Alert'"></h3>
    
    <div class="py-4">
      <div class="alert" :class="osmolarityAlert?.alert_type === 'Hard' ? 'alert-error' : 'alert-warning'">
        <div class="flex items-center gap-2">
          <svg x-show="osmolarityAlert?.alert_type === 'Hard'" xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <svg x-show="osmolarityAlert?.alert_type === 'Soft'" xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <span x-text="osmolarityAlert?.alert_type === 'Hard' ? 'Hard Alert' : 'Soft Alert'"></span>
        </div>
        <div class="mt-2">
          <p x-text="`Calculated Osmolarity: ${osmolarityAlert?.calculated?.toFixed(0) || 0} mOsm/L`"></p>
          <p x-text="`Limit: ${osmolarityAlert?.limit || 0} mOsm/L`"></p>
          <p x-text="`Exceeds limit by: ${(osmolarityAlert?.calculated - osmolarityAlert?.limit)?.toFixed(0) || 0} mOsm/L`"></p>
        </div>
      </div>
      
      <template x-if="osmolarityAlert?.alert_type === 'Soft'">
        <div class="mt-4">
          <label class="form-control">
            <div class="label">
              <span class="label-text">Comments for Override</span>
              <span class="label-text-alt text-error">Required</span>
            </div>
            <textarea 
              class="textarea textarea-bordered h-24" 
              placeholder="Please explain why you need to exceed the osmolarity limit..."
              x-model="osmolarityComments"
            ></textarea>
            <div class="label">
              <span class="label-text-alt">Comments are required to proceed with a soft alert</span>
            </div>
          </label>
        </div>
      </template>
      
      <template x-if="osmolarityAlert?.alert_type === 'Hard'">
        <div class="mt-4">
          <div class="alert alert-error">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>Hard alert cannot be overridden. Please adjust your order to reduce osmolarity.</span>
          </div>
        </div>
      </template>
    </div>
    
    <div class="modal-action">
      <template x-if="osmolarityAlert?.alert_type === 'Soft'">
        <button class="btn btn-warning" @click="handleOsmolarityAlertOverride" :disabled="!osmolarityComments.trim()">
          Override with Comments
        </button>
      </template>
      <button class="btn btn-error" @click="handleOsmolarityAlertCancel">
        Adjust Order
      </button>
      <button class="btn" @click="showOsmolarityAlertModal = false">Cancel</button>
    </div>
  </div>
</dialog>
```

#### Add Drag-and-Drop Sorting to Template Products
Update the template products section to support drag-and-drop:
```html
<div 
  x-sort="handleSort"
  @dragstart="handleDragStart($event, index)"
  @dragover="handleDragOver($event, index)"
  @dragend="handleDragEnd()"
>
  <template x-for="(product, index) in productsData" :key="product.id">
    <div 
      class="flex p-4 space-x-4 border-t border-border draggable-item"
      draggable="true"
      :class="{ 'opacity-50': isDragging && dragStartIndex === index }"
    >
      <div class="cursor-move group" @mousedown="handleDragStart(index)">
        <.icon_move class="flex-shrink size-4 text-muted-foreground group-hover:text-foreground" />
      </div>
      <!-- Rest of product fields -->
    </div>
  </template>
</div>
```

#### Add Summary Cards
Add the electrolyte and nutritional summary cards to the order form:

1. **Electrolyte Summary Card** (after template products section):
```html
<div class="card mt-6" x-show="Object.values(calculations.electrolyteTotals).some(v => v > 0)">
  <div class="card-header">
    <h3 class="card-title">Electrolyte Summary (mmol)</h3>
  </div>
  <div class="card-body grid grid-cols-4 gap-4">
    <div class="electrolyte-item" x-show="calculations.electrolyteTotals.sodium > 0">
      <span class="electrolyte-label">Sodium</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.sodium.toFixed(2)"></span>
    </div>
    <div class="electrolyte-item" x-show="calculations.electrolyteTotals.potassium > 0">
      <span class="electrolyte-label">Potassium</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.potassium.toFixed(2)"></span>
    </div>
    <div class="electrolyte-item" x-show="calculations.electrolyteTotals.calcium > 0">
      <span class="electrolyte-label">Calcium</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.calcium.toFixed(2)"></span>
    </div>
    <div class="electrolyte-item" x-show="calculations.electrolyteTotals.magnesium > 0">
      <span class="electrolyte-label">Magnesium</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.magnesium.toFixed(2)"></span>
    </div>
    <div class="electrolyte-item" x-show="calculations.electrolyteTotals.phosphate > 0">
      <span class="electrolyte-label">Phosphate</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.phosphate.toFixed(2)"></span>
    </div>
    <div class="electrolyte-item" x-show="calculations.electrolyteTotals.chloride > 0">
      <span class="electrolyte-label">Chloride</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.chloride.toFixed(2)"></span>
    </div>
    <div class="electrolyte-item" x-show="calculations.electrolyteTotals.acetate > 0">
      <span class="electrolyte-label">Acetate</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.acetate.toFixed(2)"></span>
    </div>
  </div>
</div>
```

2. **Nutritional Information Summary Card** (after electrolyte summary):
```html
<div class="card mt-6" x-show="calculations.nutritionalSummary.totalEnergy > 0">
  <div class="card-header">
    <h3 class="card-title">Nutritional Information Summary</h3>
  </div>
  <div class="card-body">
    <div class="grid grid-cols-3 gap-4">
      <div class="nutrition-item">
        <span class="nutrition-label">Protein Energy</span>
        <span class="nutrition-value" x-text="calculations.nutritionalSummary.proteinEnergy.toFixed(1)"></span>
        <span class="nutrition-unit">Kcal</span>
        <span class="nutrition-percent" 
              x-text="`(${((calculations.nutritionalSummary.proteinEnergy / calculations.nutritionalSummary.totalEnergy) * 100).toFixed(1)}%)`"
              x-show="calculations.nutritionalSummary.totalEnergy > 0">
        </span>
      </div>
      <div class="nutrition-item">
        <span class="nutrition-label">Dextrose Energy</span>
        <span class="nutrition-value" x-text="calculations.nutritionalSummary.dextroseEnergy.toFixed(1)"></span>
        <span class="nutrition-unit">Kcal</span>
        <span class="nutrition-percent" 
              x-text="`(${((calculations.nutritionalSummary.dextroseEnergy / calculations.nutritionalSummary.totalEnergy) * 100).toFixed(1)}%)`"
              x-show="calculations.nutritionalSummary.totalEnergy > 0">
        </span>
      </div>
      <div class="nutrition-item">
        <span class="nutrition-label">Lipid Energy</span>
        <span class="nutrition-value" x-text="calculations.nutritionalSummary.lipidEnergy.toFixed(1)"></span>
        <span class="nutrition-unit">Kcal</span>
        <span class="nutrition-percent" 
              x-text="`(${((calculations.nutritionalSummary.lipidEnergy / calculations.nutritionalSummary.totalEnergy) * 100).toFixed(1)}%)`"
              x-show="calculations.nutritionalSummary.totalEnergy > 0">
        </span>
      </div>
      <div class="nutrition-item">
        <span class="nutrition-label">Total Energy</span>
        <span class="nutrition-value" x-text="calculations.nutritionalSummary.totalEnergy.toFixed(1)"></span>
        <span class="nutrition-unit">Kcal</span>
      </div>
      <div class="nutrition-item">
        <span class="nutrition-label">Nitrogen</span>
        <span class="nutrition-value" x-text="calculations.nutritionalSummary.nitrogen.toFixed(2)"></span>
        <span class="nutrition-unit">g</span>
      </div>
      <div class="nutrition-item">
        <span class="nutrition-label">Total Kcal/Nitrogen</span>
        <span class="nutrition-value" x-text="calculations.nutritionalSummary.totalKcalPerNitrogen.toFixed(1)"></span>
        <span class="nutrition-unit">Kcal/g</span>
      </div>
    </div>
  </div>
</div>
```

#### Add Summary Cards to Order Form

1. **Electrolyte Summary Card** (`order_components_html/electrolyte_summary.html.heex`):
```html
<div class="card mt-6">
  <div class="card-header">
    <h3 class="card-title">Electrolyte Summary</h3>
  </div>
  <div class="card-body grid grid-cols-4 gap-4">
    <div class="electrolyte-item">
      <span class="electrolyte-label">Total Sodium</span>
      <span class="electrolyte-value" x-text="calculations.electrolyteTotals.sodium.toFixed(2)"></span>
      <span class="electrolyte-unit">mmol</span>
    </div>
    <!-- Repeat for other electrolytes -->
  </div>
</div>
```

2. **Nutritional Information Summary Card** (`order_components_html/nutritional_summary.html.heex`):
```html
<div class="card mt-6">
  <div class="card-header">
    <h3 class="card-title">Nutritional Information Summary</h3>
  </div>
  <div class="card-body">
    <div class="grid grid-cols-3 gap-4">
      <div class="nutrition-item">
        <span class="nutrition-label">Protein Energy</span>
        <span class="nutrition-value" x-text="calculations.nutritionalSummary.proteinEnergy.toFixed(1)"></span>
        <span class="nutrition-unit">Kcal</span>
        <span class="nutrition-percent" x-text="`(${((calculations.nutritionalSummary.proteinEnergy / calculations.nutritionalSummary.totalEnergy) * 100).toFixed(1)}%)`"></span>
      </div>
      <!-- Repeat for other nutritional values -->
    </div>
  </div>
</div>
```

#### Enhance Child Table Calculations
Update `template_products.html.heex` to include real-time calculations and sorting:

1. **Add calculation triggers to input fields**:
```html
<input
  name="template_dose"
  id="template_dose"
  x-model="product.dose"
  type="number"
  step=".0001"
  class="input input-sm input-bordered"
  @input="calculateAll()"
/>
```

2. **Display calculated values**:
```html
<label class="form-control w-full max-w-xs grid gap-3" for="template_volume">
  <div class="label">
    <span class="label-text">Volume (mL)</span>
  </div>
  <input
    name="template_volume"
    id="template_volume"
    x-model="product.volume"
    type="number"
    step=".0001"
    class="input input-sm input-read-only"
    readonly
    x-text="product.volume ? product.volume.toFixed(4) : '0.0000'"
  />
</label>
<label class="form-control w-full max-w-xs grid gap-3" for="template_fill_volume">
  <div class="label">
    <span class="label-text">Fill Volume (mL)</span>
  </div>
  <input
    name="template_fill_volume"
    id="template_fill_volume"
    x-model="product.fill_volume"
    type="number"
    step=".0001"
    class="input input-sm input-read-only"
    readonly
    x-text="product.fill_volume ? product.fill_volume.toFixed(4) : '0.0000'"
  />
</label>
```

3. **Add status-based field disabling**:
```html
<input
  name="template_dose"
  id="template_dose"
  x-model="product.dose"
  type="number"
  step=".0001"
  class="input input-sm input-bordered"
  @input="calculateAll()"
  :disabled="orderStatus !== 'draft' && product.substance_locked_on_order"
/>
```

### Phase 4: Backend Integration

#### Create Osmolarity API Controller (`lib/tpn_web/controllers/api/osmolarity_controller.ex`)
```elixir
defmodule TpnWeb.Api.OsmolarityController do
  use TpnWeb, :controller
  
  alias Tpn.Calculations.OsmolarityValidation
  
  def get_limit(conn, %{"patient_type_id" => patient_type_id, "vascular_access_id" => vascular_access_id}) do
    case OsmolarityValidation.get_osmolarity_limit_api(String.to_integer(patient_type_id), String.to_integer(vascular_access_id)) do
      {:ok, osmolarity} ->
        json(conn, osmolarity)
      
      {:error, :not_found, message} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: message})
    end
  end
  
  def validate(conn, %{
        "calculated_osmolarity" => calculated_osmolarity,
        "patient_type_id" => patient_type_id,
        "vascular_access_id" => vascular_access_id
      }) do
    
    case OsmolarityValidation.get_osmolarity_limit(String.to_integer(patient_type_id), String.to_integer(vascular_access_id)) do
      {:ok, limit_record} ->
        validation_result = OsmolarityValidation.validate_osmolarity(
          Decimal.new(calculated_osmolarity),
          limit_record
        )
        
        json(conn, validation_result)
      
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "No osmolarity limit configuration found"})
    end
  end
end
```

#### Update Orders Controller (`lib/tpn_web/controllers/hospital/orders/orders_controller.ex`)
Add handling for calculated data, product preservation, and osmolarity validation:

```elixir
def create(conn, %{"order" => order_params} = params) do
  user_id = conn.assigns.current_user.id
  patient_id = params["patient_id"]
  admission_id = params["admission_id"]

  # Generate unique bag_id
  bag_id = generate_bag_id()

  # Parse JSON fields from frontend
  order_attrs =
    order_params
    |> parse_json_field(:order_calculations)
    |> parse_json_field(:order_products)
    |> parse_json_field(:calculation_snapshots)
    |> parse_json_field(:product_snapshots)
    |> parse_json_field(:osmolarity_alerts)
    |> Map.put("user_id", user_id)
    |> Map.put("patient_id", patient_id)
    |> Map.put("admission_id", admission_id)
    |> Map.put("bag_id", bag_id)
    |> Map.put("order_date", NaiveDateTime.utc_now())
    |> Map.put("osmolarity_comments", Map.get(order_params, "osmolarity_comments"))

  # Validate osmolarity alerts before proceeding
  case validate_osmolarity_alerts(order_attrs, conn) do
    {:ok, _} ->
      case Orders.create_order(order_attrs) do
        {:ok, order} ->
          status = Map.get(order_attrs, "status", "draft")
          
          # Create snapshots when status changes
          if status != "draft" do
            create_status_snapshot(order, status, order_attrs)
          end

          message =
            case status do
              "draft" -> "Order saved as draft successfully"
              "pending" -> "Order created and submitted for review"
              _ -> "Order created successfully"
            end

          conn
          |> put_resp_header(
            "hx-trigger",
            ClientEvents.generate_client_event(
              "",
              "success",
              message
            )
          )
          |> send_resp(204, "")

        {:error, %Ecto.Changeset{} = changeset} ->
          # Handle error with restored data
          handle_order_error(conn, changeset, patient_id, order_params)
      end
    
    {:error, message} ->
      conn
      |> put_flash(:error, message)
      |> put_status(:unprocessable_entity)
      |> render(:new, 
          patient_id: patient_id,
          changeset: Order.changeset(%Order{}, order_attrs),
          # ... other assigns ...
        )
  end
end

defp validate_osmolarity_alerts(order_attrs, conn) do
  osmolarity_alerts = Map.get(order_attrs, "osmolarity_alerts", %{})
  
  # If no osmolarity alert data, skip validation
  if map_size(osmolarity_alerts) == 0 do
    {:ok, :no_validation}
  else
    case Tpn.Calculations.OsmolarityValidation.can_proceed_with_order(
           osmolarity_alerts,
           Map.get(order_attrs, "osmolarity_comments")
         ) do
      {:ok, :proceed} ->
        {:ok, :proceed}
      
      {:ok, :proceed_with_override} ->
        {:ok, :proceed_with_override}
      
      {:warning, :soft_alert_requires_comments} ->
        {:error, "Soft osmolarity alert requires comments to proceed"}
      
      {:error, :hard_alert} ->
        {:error, "Hard osmolarity alert: Order exceeds osmolarity limit and cannot be overridden"}
    end
  end
end

defp parse_json_field(attrs, field) when is_map(attrs) do
  case Map.get(attrs, Atom.to_string(field)) do
    nil -> attrs
    value when is_binary(value) ->
      case Jason.decode(value) do
        {:ok, decoded} -> Map.put(attrs, Atom.to_string(field), decoded)
        _ -> Map.put(attrs, Atom.to_string(field), %{})
      end
    value -> Map.put(attrs, Atom.to_string(field), value)
  end
end

defp create_status_snapshot(order, status, order_attrs) do
  # Store calculations, products, and osmolarity alerts at the time of status change
  calculations = Map.get(order_attrs, "order_calculations", %{})
  products = Map.get(order_attrs, "order_products", %{})
  osmolarity_alerts = Map.get(order_attrs, "osmolarity_alerts", %{})
  
  snapshot = %{
    "calculated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
    "calculations" => calculations,
    "products" => products,
    "osmolarity_alerts" => osmolarity_alerts,
    "osmolarity_comments" => Map.get(order_attrs, "osmolarity_comments")
  }
  
  # Update order with snapshot
  order
  |> Ecto.Changeset.change(%{
    "calculation_snapshots" => Map.put(order.calculation_snapshots || %{}, status, snapshot),
    "product_snapshots" => Map.put(order.product_snapshots || %{}, status, snapshot),
    "osmolarity_alerts" => osmolarity_alerts,
    "osmolarity_comments" => Map.get(order_attrs, "osmolarity_comments")
  })
  |> Tpn.Repo.update()
end
```

#### Create Calculation Service (`lib/tpn/calculations/order_calculations.ex`)
```elixir
defmodule Tpn.Calculations.OrderCalculations do
  alias Tpn.{Order, Formulary, Template, TemplateProduct}
  import Ecto.Query, warn: false
  
  @doc """
  Calculate all order values based on template, products, and patient data.
  Returns a map with all calculated values.
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
    bag_volume = Map.get(template, :fluids) || 0
    tpn_duration = Map.get(order_attrs, "tpn_infusion_duration_hours") || 24
    lipid_duration = Map.get(order_attrs, "lipid_infusion_duration_hours") || 0
    
    tpn_rate = if tpn_duration > 0, do: Decimal.div(bag_volume, tpn_duration), else: Decimal.new(0)
    
    infusion_calculations = %{
      "tpn_rate" => tpn_rate,
      "lipid_rate" => Decimal.new(0), # Will be calculated with lipid product
      "total_fluids" => Decimal.new(0),
      "custom_tpn_rate" => Map.get(order_attrs, "custom_tpn_rate") || tpn_rate
    }
    
    Map.put(acc, "infusion_calculations", infusion_calculations)
  end
  
  defp calculate_nutritional_values(acc, order_attrs, products_data, template) do
    bag_volume = Map.get(template, :fluids) || 0
    dosing_weight = Decimal.new(Map.get(order_attrs, "dosing_weight") || 0)
    tpn_duration = Map.get(order_attrs, "tpn_infusion_duration_hours") || 24
    lipid_duration = Map.get(order_attrs, "lipid_infusion_duration_hours") || 0
    
    # Find key products
    amino_acid_product = find_product_by_class(products_data, ["amino", "protein"])
    dextrose_product = find_product_by_class(products_data, ["dextrose", "glucose"])
    lipid_product = find_product_by_class(products_data, ["lipid", "fat"])
    
    calculations = %{}
    
    # Calculate GIR
    if dextrose_product && Decimal.gt?(dosing_weight, 0) && tpn_duration > 0 do
      dextrose_dose_mg = Decimal.mult(dextrose_product["dose"] || 0, 1000)
      gir = Decimal.div(dextrose_dose_mg, dosing_weight)
      gir = Decimal.div(gir, tpn_duration * 60)
      calculations = Map.put(calculations, "gir", gir)
    end
    
    # Calculate percentages
    if amino_acid_product && Decimal.gt?(Decimal.new(bag_volume), 0) do
      amino_percent = Decimal.mult(amino_acid_product["dose"] || 0, 100)
      amino_percent = Decimal.div(amino_percent, bag_volume)
      calculations = Map.put(calculations, "amino_acid_percent", amino_percent)
    end
    
    if dextrose_product && Decimal.gt?(Decimal.new(bag_volume), 0) do
      dextrose_percent = Decimal.mult(dextrose_product["dose"] || 0, 100)
      dextrose_percent = Decimal.div(dextrose_percent, bag_volume)
      calculations = Map.put(calculations, "dextrose_percent", dextrose_percent)
    end
    
    # Calculate fat infusion rate
    if lipid_product && Decimal.gt?(dosing_weight, 0) && lipid_duration > 0 do
      fat_rate = Decimal.div(lipid_product["dose"] || 0, dosing_weight)
      fat_rate = Decimal.div(fat_rate, lipid_duration)
      calculations = Map.put(calculations, "fat_infusion_rate", fat_rate)
    end
    
    # Calculate osmolarity
    total_osmoles = calculate_total_osmoles(products_data)
    osmolarity = if Decimal.gt?(Decimal.new(bag_volume), 0) do
      Decimal.div(total_osmoles, Decimal.div(bag_volume, 1000))
    else
      Decimal.new(0)
    end
    calculations = Map.put(calculations, "osmolarity", osmolarity)
    
    Map.put(acc, "nutritional_calculations", calculations)
  end
  
  defp calculate_electrolyte_totals(acc, products_data) do
    electrolyte_totals = %{
      "sodium" => Decimal.new(0),
      "potassium" => Decimal.new(0),
      "calcium" => Decimal.new(0),
      "magnesium" => Decimal.new(0),
      "phosphate" => Decimal.new(0),
      "chloride" => Decimal.new(0),
      "acetate" => Decimal.new(0)
    }
    
    products_data
    |> Enum.reduce(electrolyte_totals, fn product, totals ->
      product_volume = Decimal.new(product["volume"] || 0)
      ingredients = Map.get(product, "calculated_values", %{}) |> Map.get("ingredients", [])
      
      Enum.reduce(ingredients, totals, fn ingredient, acc_totals ->
        ingredient_name = String.downcase(ingredient["name"] || "")
        amount = Decimal.new(ingredient["amount"] || 0)
        
        if Map.has_key?(acc_totals, ingredient_name) do
          contribution = Decimal.mult(product_volume, amount)
          current = Map.get(acc_totals, ingredient_name)
          Map.put(acc_totals, ingredient_name, Decimal.add(current, contribution))
        else
          acc_totals
        end
      end)
    end)
    |> then(&Map.put(acc, "electrolyte_summary", &1))
  end
  
  defp calculate_nutritional_summary(acc, products_data) do
    amino_acid_product = find_product_by_class(products_data, ["amino", "protein"])
    dextrose_product = find_product_by_class(products_data, ["dextrose", "glucose"])
    lipid_product = find_product_by_class(products_data, ["lipid", "fat"])
    
    amino_dose = Decimal.new(amino_acid_product["dose"] || 0)
    dextrose_dose = Decimal.new(dextrose_product["dose"] || 0)
    lipid_dose = Decimal.new(lipid_product["dose"] || 0)
    
    protein_energy = Decimal.mult(amino_dose, 4)
    dextrose_energy = Decimal.mult(dextrose_dose, Decimal.new("3.4"))
    lipid_energy = Decimal.mult(lipid_dose, 9)
    nitrogen = Decimal.div(amino_dose, Decimal.new("6.25"))
    non_protein_energy = Decimal.add(dextrose_energy, lipid_energy)
    total_energy = Decimal.add(protein_energy, non_protein_energy)
    
    summary = %{
      "protein_energy" => protein_energy,
      "dextrose_energy" => dextrose_energy,
      "lipid_energy" => lipid_energy,
      "nitrogen" => nitrogen,
      "non_protein_energy" => non_protein_energy,
      "total_energy" => total_energy
    }
    
    # Calculate ratios
    summary =
      if Decimal.gt?(nitrogen, 0) do
        summary
        |> Map.put("total_kcal_per_nitrogen", Decimal.div(total_energy, nitrogen))
        |> Map.put("protein_energy_per_nitrogen", Decimal.div(protein_energy, nitrogen))
        |> Map.put("non_protein_energy_per_nitrogen", Decimal.div(non_protein_energy, nitrogen))
      else
        summary
      end
    
    summary =
      if Decimal.gt?(non_protein_energy, 0) do
        Map.put(summary, "protein_to_non_protein_ratio", Decimal.div(protein_energy, non_protein_energy))
      else
        summary
      end
    
    summary =
      if Decimal.gt?(total_energy, 0) do
        Map.put(summary, "lipid_to_total_energy_ratio", Decimal.div(lipid_energy, total_energy))
      else
        summary
      end
    
    Map.put(acc, "nutritional_summary", summary)
  end
  
  defp calculate_total_osmoles(products_data) do
    products_data
    |> Enum.reduce(Decimal.new(0), fn product, total ->
      volume = Decimal.new(product["volume"] || 0)
      osmolarity = Decimal.new(product["calculated_values"]["osmolarity"] || 0)
      Decimal.add(total, Decimal.mult(volume, osmolarity))
    end)
  end
  
  defp find_product_by_class(products_data, class_keywords) do
    products_data
    |> Enum.find(fn product ->
      class_name = String.downcase(product["class_name"] || "")
      Enum.any?(class_keywords, &String.contains?(class_name, &1))
    end)
  end
  
  defp add_metadata(acc) do
    Map.put(acc, "calculated_at", DateTime.utc_now() |> DateTime.to_iso8601())
  end
end
#### Update Order Schema Validation
Add validation for order status transitions, data preservation, and osmolarity alerts:

```elixir
defmodule Tpn.Order do
  use Ecto.Schema
  import Ecto.Changeset
  
  # ... existing schema ...
  
  def status_transition_changeset(order, attrs) do
    order
    |> cast(attrs, [:status, :osmolarity_comments])
    |> validate_status_transition()
    |> validate_required([:status])
    |> validate_osmolarity_alerts()
    |> add_status_snapshot()
  end
  
  defp validate_status_transition(changeset) do
    current_status = get_field(changeset, :status)
    original_status = get_field(changeset.data, :status)
    
    valid_transitions = %{
      "draft" => ["pending", "cancelled"],
      "pending" => ["approved", "rejected", "cancelled"],
      "rejected" => ["pending", "cancelled"],
      "approved" => ["cancelled"]
    }
    
    if original_status && current_status != original_status do
      allowed = Map.get(valid_transitions, original_status, [])
      if current_status in allowed do
        changeset
      else
        add_error(changeset, :status, "Invalid status transition from #{original_status} to #{current_status}")
      end
    else
      changeset
    end
  end
  
  defp add_status_snapshot(changeset) do
    current_status = get_field(changeset, :status)
    original_status = get_field(changeset.data, :status)
    
    if current_status && current_status != original_status do
      # Create snapshot of current calculations, products, and osmolarity alerts
      calculations = get_field(changeset, :order_calculations) || %{}
      products = get_field(changeset, :order_products) || %{}
      osmolarity_alerts = get_field(changeset, :osmolarity_alerts) || %{}
      osmolarity_comments = get_field(changeset, :osmolarity_comments)
      
      snapshot = %{
        "calculated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "calculations" => calculations,
        "products" => products,
        "osmolarity_alerts" => osmolarity_alerts,
        "osmolarity_comments" => osmolarity_comments
      }
      
      # Update snapshots maps
      calculation_snapshots = get_field(changeset, :calculation_snapshots) || %{}
      product_snapshots = get_field(changeset, :product_snapshots) || %{}
      
      changeset
      |> put_change(:calculation_snapshots, Map.put(calculation_snapshots, current_status, snapshot))
      |> put_change(:product_snapshots, Map.put(product_snapshots, current_status, snapshot))
      |> put_change(:osmolarity_alerts, osmolarity_alerts)
      |> put_change(:osmolarity_comments, osmolarity_comments)
    else
      changeset
    end
  end
  
  defp validate_osmolarity_alerts(changeset) do
    osmolarity_alerts = get_field(changeset, :osmolarity_alerts) || %{}
    osmolarity_comments = get_field(changeset, :osmolarity_comments)
    status = get_field(changeset, :status) || get_field(changeset.data, :status)
    
    # Only validate for non-draft statuses
    if status != "draft" && map_size(osmolarity_alerts) > 0 do
      case Tpn.Calculations.OsmolarityValidation.can_proceed_with_order(
             osmolarity_alerts,
             osmolarity_comments
           ) do
        {:ok, _} ->
          changeset
        
        {:warning, :soft_alert_requires_comments} ->
          add_error(changeset, :osmolarity_comments, "Comments required for soft osmolarity alert")
        
        {:error, :hard_alert} ->
          add_error(changeset, :base, "Hard osmolarity alert: Order exceeds osmolarity limit")
      end
    else
      changeset
    end
  end
  
  # Validate that draft orders can be edited, but non-draft orders have restricted edits
  defp validate_editable_fields(changeset) do
    current_status = get_field(changeset, :status) || get_field(changeset.data, :status)
    
    if current_status != "draft" do
      # For non-draft orders, only allow status changes and certain fields
      allowed_fields = [
        :status,
        :calculation_snapshots,
        :product_snapshots,
        :osmolarity_alerts,
        :osmolarity_comments,
        :premixed_bag_batch_number,
        :premixed_bag_expiry
      ]
      
      # Check if any non-allowed fields are being changed
      changed_fields = Map.keys(changeset.changes)
      disallowed_changes = Enum.filter(changed_fields, &(&1 not in allowed_fields))
      
      if Enum.any?(disallowed_changes) do
        add_error(changeset, :base, "Cannot edit order fields when status is #{current_status}")
      else
        changeset
      end
    else
      changeset
    end
  end
end
```


#### Update Orders Context for Status Management
```elixir
defmodule Tpn.Orders do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Order
  
  # ... existing functions ...
  
  def update_order_status(order_id, status, user_id) do
    order = Repo.get!(Order, order_id)
    
    changeset = 
      order
      |> Order.status_transition_changeset(%{status: status})
      |> Ecto.Changeset.put_change(:user_id, user_id)  # Track who changed the status
    
    case Repo.update(changeset) do
      {:ok, updated_order} ->
        # Log the status change
        log_status_change(updated_order, user_id)
        {:ok, updated_order}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end
  
  defp log_status_change(order, user_id) do
    # Create audit log entry for status change
    # This could be stored in a separate audit_logs table
    %{
      order_id: order.id,
      user_id: user_id,
      from_status: order.__meta__.state.original.status,
      to_status: order.status,
      changed_at: DateTime.utc_now(),
      calculations_snapshot: order.calculation_snapshots[order.status],
      products_snapshot: order.product_snapshots[order.status],
      osmolarity_alerts: order.osmolarity_alerts,
      osmolarity_comments: order.osmolarity_comments
    }
  end
  
  def get_order_with_snapshots(order_id) do
    order = Repo.get!(Order, order_id)
    
    # Load additional data for display
    order_with_data = 
      order
      |> Repo.preload([:template, :formulary, :vascular_access, :patient, :admission])
    
    # Add snapshots for each status
    snapshots = %{
      draft: order.calculation_snapshots["draft"],
      pending: order.calculation_snapshots["pending"],
      approved: order.calculation_snapshots["approved"],
      rejected: order.calculation_snapshots["rejected"]
    }
    
    %{order: order_with_data, snapshots: snapshots}
  end
end
```

#### Update Router for Osmolarity API (`lib/tpn_web/router.ex`)
Add API routes for osmolarity validation:
```elixir
scope "/api", TpnWeb.Api do
  pipe_through [:api, :require_authenticated_user]
  
  # ... existing routes ...
  
  # Osmolarity API
  get "/osmolarities/limit", OsmolarityController, :get_limit
  post "/osmolarities/validate", OsmolarityController, :validate
end
```

### Phase 5: Validation, Error Handling, and Order Status Workflow

#### Implement Validation Rules

1. **Field Dependencies Based on Order Type**:
   ```javascript
   window.tpnValidation = {
     validateFieldDependencies(orderData, template) {
       const errors = [];
       const warnings = [];
       
       // Batch Production orders have different requirements
       if (orderData.order_type === 'Batch Production') {
         // These fields should be disabled for Batch Production
         const batchProductionDisabledFields = [
           'dosing_weight', 'tpn_infusion_duration_hours',
           'lipid_infusion_duration_hours', 'enteral_dose'
         ];
         
         batchProductionDisabledFields.forEach(field => {
           if (orderData[field]) {
             warnings.push(`${field} is disabled for Batch Production orders`);
           }
         });
       } else {
         // Patient-specific order validations
         if (!orderData.dosing_weight || orderData.dosing_weight <= 0) {
           errors.push('Dosing weight is required and must be greater than 0');
         }
         
         if (!orderData.tpn_infusion_duration_hours || orderData.tpn_infusion_duration_hours <= 0) {
           errors.push('TPN infusion duration is required and must be greater than 0');
         }
       }
       
       return { errors, warnings };
     }
   };
   ```

2. **Template-Based Validation**:
   ```javascript
   validateTemplateDependencies(orderData, template) {
     const errors = [];
     
     // Pre-mixed standard template validations
     if (template.pre_mixed_standard) {
       if (orderData.custom_tpn_rate) {
         const maxVolume = orderData.custom_tpn_rate * orderData.tpn_infusion_duration_hours;
         if (maxVolume > template.fluids) {
           errors.push('Custom TPN rate exceeds bag volume');
         }
       }
       
       // Validate total fluids don't exceed template fluids
       if (orderData.total_fluids > template.fluids) {
         errors.push('Total fluids exceed template bag volume');
       }
     }
     
     // 3-in-1 vs 2-in-1 infusion type validations
     if (orderData.tpn_infusion_type === '3_in_1') {
       if (orderData.lipid_infusion_duration_hours) {
         warnings.push('Lipid infusion duration is disabled for 3-in-1 bags');
       }
     }
     
     return errors;
   }
   ```

3. **Calculated Value Validation**:
   4. **Osmolarity Validation**:
      ```javascript
      validateCalculatedValues(calculations, orderData, osmolarityAlert) {
        const errors = [];
        const warnings = [];
      
        // GIR validation (typical range: 4-12 mg/kg/min)
        if (calculations.nutritional.gir < 4 || calculations.nutritional.gir > 12) {
          warnings.push(`GIR (${calculations.nutritional.gir.toFixed(2)}) is outside typical range (4-12 mg/kg/min)`);
        }
      
        // Amino acid % validation (typical range: 2-5%)
        if (calculations.nutritional.aminoAcidPercent < 2 || calculations.nutritional.aminoAcidPercent > 5) {
          warnings.push(`Amino acid % (${calculations.nutritional.aminoAcidPercent.toFixed(2)}%) is outside typical range (2-5%)`);
        }
      
        // Dextrose % validation (typical range: 5-25%)
        if (calculations.nutritional.dextrosePercent < 5 || calculations.nutritional.dextrosePercent > 25) {
          warnings.push(`Dextrose % (${calculations.nutritional.dextrosePercent.toFixed(2)}%) is outside typical range (5-25%)`);
        }
      
        // Osmolarity validation based on alert system
        if (osmolarityAlert) {
          if (osmolarityAlert.exceeds_limit && osmolarityAlert.alert_type === 'Hard') {
            errors.push(`Hard osmolarity alert: ${osmolarityAlert.calculated.toFixed(0)} mOsm/L exceeds limit of ${osmolarityAlert.limit} mOsm/L`);
          } else if (osmolarityAlert.exceeds_limit && osmolarityAlert.alert_type === 'Soft' && !osmolarityAlert.override) {
            warnings.push(`Soft osmolarity alert: ${osmolarityAlert.calculated.toFixed(0)} mOsm/L exceeds limit of ${osmolarityAlert.limit} mOsm/L. Comments required.`);
          }
        }
      
        // Fat infusion rate validation (typical max: 0.15 g/kg/hour)
        if (calculations.nutritional.fatInfusionRate > 0.15) {
          warnings.push(`Fat infusion rate (${calculations.nutritional.fatInfusionRate.toFixed(2)} g/kg/hour) exceeds typical maximum (0.15 g/kg/hour)`);
        }
      
        return { errors, warnings };
      }
    };
    ```
 
 4. **Order Status Validation**:
    ```javascript
    validateOrderStatus(orderStatus, originalStatus) {
      const validTransitions = {
        'draft': ['pending', 'cancelled'],
        'pending': ['approved', 'rejected', 'cancelled'],
        'rejected': ['pending', 'cancelled'],
        'approved': ['cancelled']
      };
      
      if (originalStatus && orderStatus !== originalStatus) {
        const allowed = validTransitions[originalStatus] || [];
        if (!allowed.includes(orderStatus)) {
          return `Invalid status transition from ${originalStatus} to ${orderStatus}`;
        }
      }
      
      return null;
    }
    ```
 
 5. **User Feedback System**:
    - Real-time validation messages displayed next to fields
    - Warning alerts for borderline values with option to override
    - Error prevention with field disabling for invalid combinations
    - Summary of all validation issues before submission

 #### Add Alpine.js Validation Helpers
 Extend the existing `tpnValidation` object with comprehensive validation functions.

 ## Implementation Priority

 ### High Priority (Phase 1)
 1. Data model enhancements with map fields for calculations, products, and osmolarity alerts
 2. Basic infusion calculations (TPN rate, lipid rate, total fluids)
 3. Substance volume and fill volume calculations
 4. Product sorting preservation in order form
 5. Osmolarity calculation and basic validation

 ### Medium Priority (Phase 2)
 1. Nutritional calculations (GIR, amino acid %, dextrose %, fat infusion rate)
 2. Electrolyte summary calculations
 3. Nutritional summary calculations
 4. Osmolarity alert system with patient type and vascular access integration
 5. UI summary cards for electrolytes and nutrition
 6. Osmolarity alert modal with soft/hard alert handling

 ### Low Priority (Phase 3)
 1. Advanced validation rules with medical ranges
 2. Comprehensive error handling and user feedback
 3. Order status workflow with snapshot preservation
 4. Performance optimizations for calculations
 5. Audit trail and version history
 6. Export functionality for calculations

 ## Testing Strategy

 ### Frontend Tests
 - Unit tests for calculation functions using Jest or similar
 - Integration tests for form interactions and sorting
 - Validation test cases for different order types and templates
 - Cross-browser compatibility testing

 ### Backend Tests
 - Unit tests for calculation service in Elixir
 - Integration tests for order creation with calculations
 - Data consistency tests between frontend and backend calculations
 - Status transition validation tests

 ### Manual Testing Scenarios
 1. Different order types (PatientSpecific vs Batch Production)
 2. Different template types (pre-mixed vs custom, with/without additional substances)
 3. Different infusion types (3-in-1 vs 2-in-1)
 4. Edge cases (zero values, maximum limits, unit conversions)
 5. Order status transitions (draft → pending → approved/rejected)
 6. Product sorting and position preservation
 7. Calculation persistence across page reloads
 8. Osmolarity alert scenarios (soft vs hard alerts, with and without comments)
 9. Patient type and vascular access combinations for osmolarity limits

 ## Migration Plan

 ### Database Migrations
 1. Add new fields to orders table:
    ```elixir
    alter table(:orders) do
      add :order_calculations, :map, default: %{}
      add :order_products, :map, default: %{}
      add :calculation_snapshots, :map, default: %{}
      add :product_snapshots, :map, default: %{}
      add :osmolarity_alerts, :map, default: %{}
      add :osmolarity_comments, :text
    end
    ```
 
 2. Create order_products table (optional, for more robust solution):
    ```elixir
    create table(:order_products) do
      add :position, :integer
      add :dose, :decimal, precision: 10, scale: 4
      add :additional_dose, :decimal, precision: 10, scale: 4
      add :max_allowed_limit, :decimal, precision: 10, scale: 4
      add :volume, :decimal, precision: 10, scale: 4
      add :fill_volume, :decimal, precision: 10, scale: 4
      add :calculated_values, :map, default: %{}
      add :order_id, references(:orders, on_delete: :delete_all)
      add :template_product_id, references(:template_products, on_delete: :nilify_all)
      add :formulary_id, references(:formularies, on_delete: :nilify_all)
      add :filling_method_id, references(:filling_methods, on_delete: :nilify_all)
      timestamps()
    end
    ```

 ### Data Migration
 1. Backfill existing orders with empty calculation maps
 2. Migrate any existing calculation data from other fields
 3. Validate migrated data consistency

 ### Code Migration
 1. Update Order schema with new fields
 2. Update controllers to handle new data structures
 3. Update frontend to send/receive new data format
 4. Maintain backward compatibility during transition

 ## Rollback Plan

 ### Soft Rollback (if issues detected)
 1. Disable new calculation features via feature flag
 2. Revert to previous data structures
 3. Keep new database fields but don't use them

 ### Hard Rollback (if critical issues)
 1. Revert database migrations
 2. Revert code changes
 3. Restore from backups if necessary

 ## Monitoring and Metrics

 ### Technical Metrics
 1. Calculation accuracy (compare with manual calculations)
 2. Form load time (should not increase by more than 200ms)
 3. Real-time calculation response time (should be < 100ms)
 4. Database performance with new map fields
 5. Osmolarity alert accuracy and response time
 6. Alert override compliance tracking

 ### User Metrics
 1. User error rate reduction (target: 50% reduction)
 2. Order completion time reduction (target: 30% reduction)
 3. User satisfaction scores (target: ≥ 4.5/5)
 4. Calculation usage statistics
 5. Osmolarity alert frequency and type distribution
 6. Soft alert override rate and comment quality

 ### Error Monitoring
 1. Track calculation errors and exceptions
 2. Monitor validation failures
 3. Log status transition issues
 4. Alert on data inconsistency between frontend/backend
 5. Track osmolarity alert overrides and compliance
 6. Monitor missing osmolarity limit configurations

 ## Future Considerations

 1. **Calculation Caching**: Cache frequently used calculations to improve performance
 2. **Audit Trail**: Track calculation changes and versions for compliance
 3. **Export Functionality**: Export calculations to PDF/Excel for reporting
 4. **Bulk Operations**: Support for batch calculations for multiple orders
 5. **Advanced Analytics**: Trend analysis and nutritional optimization suggestions
 6. **Integration**: Connect with electronic health records (EHR) systems
 7. **Mobile Support**: Responsive design for mobile devices
 8. **Offline Capabilities**: Local storage for draft orders and calculations
 9. **Osmolarity Limit Management**: UI for managing osmolarity limits by patient type and vascular access
 10. **Alert Analytics**: Reporting on osmolarity alert patterns and trends

 ## Dependencies and Requirements

 ### Frontend Dependencies
 - Alpine.js v3.x (already in use)
 - HTMX (already in use)
 - Decimal.js for precise decimal arithmetic (to be added)
 - Sortable.js or similar for drag-and-drop sorting (optional)
 - Unit conversion library (to be evaluated)

 ### Backend Dependencies
 - Decimal arithmetic for Elixir (already using Decimal)
 - JSON serialization for calculation results
 - Database support for map fields (PostgreSQL jsonb)

 ### Data Requirements
 1. **Formulary Data**:
    - Complete ingredient concentrations for all formularies
    - Osmolarity values for all formularies
    - Unit definitions and conversion factors
    - Ingredient data for electrolyte calculations
    - Complete osmolarity values for all formularies

 4. **Osmolarity Limit Data**:
    - Complete osmolarity limit configurations for all patient type and vascular access combinations
    - Alert type assignments (Soft/Hard) for each limit
    - Unit consistency across all osmolarity measurements

 2. **Template Data**:
    - Accurate bag volume and overfill values
    - Fluid unit definitions
    - Patient type associations
    - Pre-mixed vs custom template flags

 3. **Order Data**:
    - Complete admission weight data
    - Accurate dosing weight calculations
    - Infusion duration preferences
    - Vascular access information

 ## Risk Mitigation

 ### Technical Risks
 1. **Calculation Accuracy**: Implement unit tests and cross-verify with medical standards
 2. **Performance Impact**: Use debouncing for real-time calculations, optimize algorithms
 3. **Data Consistency**: Implement reconciliation between frontend and backend calculations
 4. **Browser Compatibility**: Test across different browsers and devices

 ### Business Risks
 1. **Regulatory Compliance**: Ensure calculations meet healthcare regulations and standards
 2. **User Acceptance**: Provide clear documentation, training, and support for new calculations
 3. **Data Migration**: Plan for migrating existing orders with calculated values
 4. **Change Management**: Communicate changes effectively to all stakeholders
 5. **Clinical Validation**: Ensure osmolarity limits and alert types are clinically validated
 6. **Alert Fatigue**: Monitor for alert fatigue with frequent soft alerts

 ### Mitigation Strategies
 1. **Phased Rollout**: Release features gradually to limited user groups first
 2. **Feature Flags**: Enable/disable features without code deployment
 3. **Comprehensive Testing**: Extensive testing before full deployment
 4. **User Training**: Provide training materials and support resources
 5. **Clinical Review**: Have clinical experts review and approve osmolarity limits
 6. **Alert Testing**: Test alert system with various clinical scenarios

 ## Success Criteria

 ### Technical Success Criteria
 1. All calculations produce accurate results within acceptable tolerance
 2. System performance meets or exceeds baseline measurements
 3. Data integrity maintained across all operations
 4. Error rate below 0.1% for calculation operations

 ### Business Success Criteria
 1. User adoption rate > 90% for new calculation features
 2. Reduction in manual calculation errors by ≥ 50%
 3. Improvement in order processing time by ≥ 30%
 4. Positive user feedback and satisfaction scores
 5. Proper handling of osmolarity alerts (100% compliance with hard alerts)
 6. Appropriate use of soft alert overrides with meaningful comments

 ## Implementation Timeline

 ### Week 1-2: Foundation
 - Data model enhancements and migrations
 - Basic calculation functions in Alpine.js
 - Unit conversion infrastructure
 - Product sorting implementation
 - Basic osmolarity calculation

 ### Week 3-4: Core Calculations
 - Infusion rate calculations (TPN rate, lipid rate, total fluids)
 - Nutritional calculations (GIR, percentages, fat infusion rate)
 - Basic UI integration with real-time updates
 - Backend calculation service
 - Osmolarity validation API and service

 ### Week 5-6: Advanced Features
 - Electrolyte summary calculations and UI
 - Nutritional summary calculations and UI
 - Osmolarity alert system with patient type/vascular access integration
 - Osmolarity alert modal and override handling
 - Validation and error handling

 ### Week 7-8: Polish and Testing
 - Performance optimization
 - Comprehensive testing (unit, integration, user acceptance)
 - Order status workflow with snapshot preservation
 - User documentation and training materials
 - Deployment preparation

 ## Team Responsibilities

 ### Frontend Developer
 - Implement Alpine.js calculation engine
 - Enhance UI with summary cards and sorting
 - Add real-time validation and user feedback
 - Optimize performance and responsiveness

 ### Backend Developer
 - Extend data models and create migrations
 - Implement server-side calculation service
 - Add API endpoints for complex calculations
 - Ensure data consistency and integrity

 ### QA Engineer
 - Create test cases for all calculations
 - Validate accuracy against medical standards
 - Performance and load testing
 - User acceptance testing coordination

 ### Product Owner
 - Define calculation requirements and priorities
 - Coordinate user training and documentation
 - Stakeholder communication and feedback collection
 - Success metrics tracking

 ### Medical/Clinical Advisor
 - Review calculation formulas for clinical accuracy
 - Validate acceptable ranges and limits
 - Provide clinical context for validation rules
 - Approve osmolarity limits and alert types
 -

 ## Revision History

 | Version | Date | Changes | Author |
 |---------|------|---------|--------|
 | 1.0 | 2024-01-15 | Initial strategy document | AI Assistant |
 | 1.1 | 2024-01-15 | Added implementation details and timeline | AI Assistant |
 | 1.2 | 2024-01-15 | Added order product preservation and status workflow | AI Assistant |

 ## Next Steps

 1. **Immediate Actions**:
    - Review and approve this strategy with stakeholders
    - Set up project tracking for implementation phases
    - Assign team responsibilities and timelines

 2. **Short-term Tasks**:
    - Create detailed technical specifications for Phase 1
    - Set up development environment for calculation testing
    - Begin data model enhancements and migrations
    - Create prototype for basic calculations

 3. **Long-term Planning**:
    - Schedule regular review meetings with stakeholders
    - Plan user training sessions and documentation
    - Prepare for deployment and monitoring
    - Establish feedback collection process

 ## Contact Information

 For questions or clarifications about this strategy, refer to the project documentation or contact the development team lead.

 ---
 *This document is a living strategy and will be updated as implementation progresses. All calculations should be reviewed by clinical experts before deployment.*

### High Priority (Phase 1)
1. Basic infusion calculations (TPN rate, lipid rate, total fluids)
2. Substance volume and fill volume calculations
3. GIR, amino acid %, dextrose % calculations

### Medium Priority (Phase 2)
1. Electrolyte summary calculations
2. Nutritional summary calculations
3. Osmolarity calculation

### Low Priority (Phase 3)
1. Advanced validation rules
2. Comprehensive error handling
3. Performance optimizations for calculations

## Testing Strategy

### Frontend Tests
- Unit tests for calculation functions
- Integration tests for form interactions
- Validation test cases

### Backend Tests
- Unit tests for calculation service
- Integration tests for order creation with calculations
- Data consistency tests between frontend and backend

### Manual Testing Scenarios
1. Different order types (PatientSpecific vs Batch Production)
2. Different template types (pre-mixed vs custom)
3. Different infusion types (3-in-1 vs 2-in-1)
4. Edge cases (zero values, maximum limits)

## Future Considerations

1. **Calculation Caching**: Cache frequently used calculations to improve performance
2. **Audit Trail**: Track calculation changes and versions
3. **Export Functionality**: Export calculations to PDF/Excel for reporting
4. **Bulk Operations**: Support for batch calculations for multiple orders
5. **Advanced Analytics**: Trend analysis and nutritional optimization suggestions

## Dependencies and Requirements

### Frontend Dependencies
- Alpine.js v3.x (already in use)
- HTMX (already in use)
- Decimal.js for precise decimal arithmetic (to be added)
- Unit conversion library (to be evaluated)

### Backend Dependencies
- Decimal arithmetic for Elixir (already using Decimal)
- JSON serialization for calculation results
- Database migrations for new fields

### Data Requirements
1. **Formulary Data**:
   - Complete ingredient concentrations for all formularies
   - Osmolarity values for all formularies
   - Unit definitions and conversion factors

2. **Template Data**:
   - Accurate bag volume and overfill values
   - Fluid unit definitions
   - Patient type associations

3. **Order Data**:
   - Complete admission weight data
   - Accurate dosing weight calculations
   - Infusion duration preferences

## Risk Mitigation

### Technical Risks
1. **Calculation Accuracy**: Implement unit tests and cross-verify with medical standards
2. **Performance Impact**: Use debouncing for real-time calculations, optimize algorithms
3. **Data Consistency**: Implement reconciliation between frontend and backend calculations

### Business Risks
1. **Regulatory Compliance**: Ensure calculations meet healthcare regulations
2. **User Acceptance**: Provide clear documentation and training for new calculations
3. **Data Migration**: Plan for migrating existing orders with calculated values

## Success Metrics

### Technical Metrics
1. Calculation accuracy ≥ 99.9%
2. Form load time increase < 200ms
3. Real-time calculation response time < 100ms

### User Metrics
1. User error rate reduction by 50%
2. Order completion time reduction by 30%
3. User satisfaction score ≥ 4.5/5

## Implementation Timeline

### Week 1-2: Foundation
- Data model enhancements
- Basic calculation functions
- Unit conversion infrastructure

### Week 3-4: Core Calculations
- Infusion rate calculations
- Nutritional calculations
- Basic UI integration

### Week 5-6: Advanced Features
- Electrolyte summaries
- Nutritional summaries
- Validation and error handling

### Week 7-8: Polish and Testing
- Performance optimization
- Comprehensive testing
- User documentation

## Team Responsibilities

### Frontend Developer
- Implement Alpine.js calculation engine
- Enhance UI with summary cards
- Add real-time validation
- Optimize performance

### Backend Developer
- Extend data models
- Implement server-side calculations
- Add API endpoints
- Ensure data consistency

### QA Engineer
- Create test cases for calculations
- Validate accuracy against medical standards
- Performance testing
- User acceptance testing

### Product Owner
- Define calculation requirements
- Prioritize features
- User training and documentation
- Stakeholder communication

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2024-01-15 | Initial strategy document | AI Assistant |
| 1.1 | 2024-01-15 | Added implementation details and timeline | AI Assistant |

## Next Steps

1. **Immediate Actions**:
   - Review and approve this strategy
   - Set up project tracking for implementation phases
   - Assign team responsibilities

2. **Short-term Tasks**:
   - Create detailed technical specifications for Phase 1
   - Set up development environment for calculation testing
   - Begin data model enhancements

3. **Long-term Planning**:
   - Schedule regular review meetings
   - Plan user training sessions
   - Prepare for deployment and monitoring

## Contact Information

For questions or clarifications about this strategy, refer to the project documentation or contact the development team lead.

---
*This document is a living strategy and will be updated as implementation progresses.*