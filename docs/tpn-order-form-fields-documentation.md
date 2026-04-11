# TPN Order Form - Complete Field Documentation

**Version:** 1.0  
**Last Updated:** April 5, 2026  
**Purpose:** Comprehensive documentation of all fields in the TPN order form, including conditions, validations, display rules, and calculations.

---

## Table of Contents

1. [Order Types](#order-types)
2. [Basic Order Information](#basic-order-information)
3. [Patient & Admission Fields](#patient--admission-fields)
4. [Template Selection](#template-selection)
5. [Template Product Fields](#template-product-fields)
6. [Infusion Configuration](#infusion-configuration)
7. [Calculation Fields](#calculation-fields)
8. [Osmolarity Management](#osmolarity-management)
9. [Premixed Bag Fields](#premixed-bag-fields)
10. [Field Validations & Conditions](#field-validations--conditions)
11. [Calculation Formulas](#calculation-formulas)

---

## Order Types

### 1. Order Type
- **Field Name:** `order_type`
- **Data Type:** String (Short Text)
- **Options:**
  - `Patient Specific` - Standard patient-specific TPN order
  - `Batch Production` - Batch production orders (non-patient specific)
- **Display:** Mandatory field, displayed at form initialization
- **Default:** `Patient Specific`
- **Validation:** Required
- **Conditions:**
  - When `Batch Production` is selected:
    - Most patient-specific fields become optional
    - Vascular access, enteral dose, TPN infusion type, infusion duration type, TPN/lipid infusion hours, and dosing weight are NOT required
  - When `Patient Specific` is selected:
    - All standard validations apply
- **Notes:** Affects which fields are required throughout the form

---

## Basic Order Information

### 2. Order ID
- **Field Name:** `id`
- **Data Type:** Number (Auto-generated)
- **Display:** Auto-generated, not editable
- **Validation:** System-generated primary key
- **Conditions:** Always present after order creation

### 3. Bag ID
- **Field Name:** `bag_id`
- **Data Type:** String
- **Display:** Auto-generated when order is created
- **Validation:** Required, mandatory
- **Generation Logic:** `timestamp_random` (e.g., `1680123456_7823`)
- **Conditions:** Generated when batch production or patient-specific order is created
- **Notes:** Unique identifier for the TPN bag

### 4. Order Date
- **Field Name:** `order_date`
- **Data Type:** Naive DateTime
- **Display:** Auto-filled with current date/time
- **Validation:** Required, mandatory
- **Default:** `NaiveDateTime.utc_now()`
- **Conditions:** Set automatically on order creation

### 5. Status
- **Field Name:** `status`
- **Data Type:** String (Short Text)
- **Options:**
  - `draft` - Order saved but not submitted
  - `pending` - Order submitted, awaiting review
  - `approved` - Order approved by reviewer
  - `rejected` - Order rejected by reviewer
- **Display:** Controlled by form buttons
- **Default:** `draft`
- **Validation:** Must be one of the defined statuses
- **Conditions:**
  - "Save as Draft" button sets status to `draft`
  - "Create Order" button sets status to `pending`
- **Workflow:**
  - draft → pending (user submits)
  - pending → approved (reviewer approves)
  - pending → rejected (reviewer rejects)
  - rejected → pending (user resubmits)

### 6. Copy Order
- **Field Name:** `copy_order`
- **Data Type:** Yes/No (Boolean)
- **Display:** Checkbox or toggle
- **Default:** `false`
- **Validation:** Optional
- **Conditions:** When true, indicates order is copied from another order
- **Related Field:** `copied_from_order_id`

### 7. Copied From Order ID
- **Field Name:** `copied_from_order_id`
- **Data Type:** Number
- **Display:** Hidden, populated when copying an order
- **Validation:** Optional
- **Conditions:** Only populated when `copy_order` is true
- **Notes:** References the original order ID

### 8. Number of Bags
- **Field Name:** `number_of_bags`
- **Data Type:** Number (Integer)
- **Display:** Input field
- **Default:** `1`
- **Validation:** Required for batch production
- **Conditions:**
  - Editable when batch production is selected
  - Mandatory for batch production
  - Lock value from vascular access table if available
- **Notes:** Determines how many bags to produce

---

## Patient & Admission Fields

### 9. Patient ID
- **Field Name:** `patient_id`
- **Data Type:** Number
- **Display:** Hidden field, auto-populated
- **Validation:** Required, mandatory
- **Conditions:** Populated from URL parameter or patient selection
- **Notes:** Links order to specific patient

### 10. Admission ID
- **Field Name:** `admission_id`
- **Data Type:** Number
- **Display:** Hidden field, auto-populated
- **Validation:** Required for patient-specific orders
- **Conditions:** Populated from admission context
- **Notes:** Links order to patient's current admission

### 11. Patient Type ID
- **Field Name:** `patient_type_id` (from admission)
- **Data Type:** Number
- **Display:** Hidden, derived from admission
- **Validation:** Required
- **Source:** `admission.patient_type_id`
- **Conditions:** Used for filtering templates, formularies, and osmolarity limits
- **Notes:** Critical for determining appropriate vascular access options and osmolarity limits

### 12. Dosing Weight
- **Field Name:** `dosing_weight`
- **Data Type:** String (Short Text)
- **Display:** Number input with unit label from admission
- **Validation:** Required for patient-specific orders
- **Unit:** From `admission.weight_unit`
- **Default:** Pre-filled from `admission.patient_weight`
- **Conditions:**
  - Mandatory for patient-specific orders
  - Editable
  - Disable if Order Type is Batch Production
- **Notes:** Used in GIR and other weight-based calculations

---

## Template Selection

### 13. Template ID
- **Field Name:** `template_id`
- **Data Type:** Number
- **Display:** Dropdown select (simple-select)
- **Validation:** Required, mandatory
- **Options:** Filtered by `patient_type_id`
- **Conditions:**
  - Lookup value from Template table
  - Filter based on Patient Type
  - If premixed standard template is selected, lock all substances and doses in child table except additional dose is allowed on Template
- **Trigger:** HTMX request to load template products
- **Notes:** Determines which products are available

### 14. Template Fluids
- **Field Name:** `template_fluids`
- **Data Type:** Map/JSONB
- **Display:** Auto-filled from template
- **Validation:** Optional
- **Source:** Template's fluid configuration
- **Conditions:** Populated when template is selected

### 15. Template Properties
- **Field Name:** `template_properties`
- **Data Type:** Map/JSONB
- **Display:** Not directly visible
- **Validation:** Optional
- **Conditions:** Stores additional template metadata

### 16. Fluids (TPN + Lipids)
- **Field Name:** `template_fluids` (from template)
- **Data Type:** Short Text
- **Display:** Input field, editable
- **Unit:** From template's `fluid_unit`
- **Validation:** Mandatory
- **Conditions:**
  - Auto-fill corresponding value from Template selected
  - Editable
  - Locked if pre-mixed bag is selected
- **Notes:** Total fluids for the order

### 17. Fluid Units
- **Field Name:** `fluid_units` (from template)
- **Data Type:** Short Text
- **Display:** Label next to fluids field
- **Validation:** Auto-filled from corresponding template
- **Conditions:** Non-editable, locked if pre-mixed bag is selected

---

## Template Product Fields

### Child Table - Substances

Each template has associated substances/products that can be selected and dosed.

### 18. Substances
- **Field Name:** `substances` (array of products)
- **Data Type:** Number (count)
- **Display:** Table with multiple rows
- **Conditions:**
  - Populate based on Template selected
  - Editable, can add more classes or delete
  - Move classes up and down within the table (can't add, delete and move if locked on Template)

### 19. Class
- **Field Name:** `class_id` (per product)
- **Data Type:** Number
- **Display:** Dropdown based on template
- **Validation:** Populate based on Template selected
- **Conditions:**
  - Editable, can add more classes or delete
  - Move classes up and down within the table

### 20. Dose
- **Field Name:** `dose` (per product)
- **Data Type:** Number (Decimal)
- **Display:** Number input
- **Validation:** Populate based on Template selected
- **Conditions:** Non-editable if user is prescriber

### 21. Dose Units
- **Field Name:** `dose_units` (per product)
- **Data Type:** Short Text
- **Display:** Label or dropdown
- **Validation:** Populate based on Template selected
- **Conditions:** Populate based on Template selected, Non-editable if user is prescriber

### 22. Product (Formulary)
- **Field Name:** `formulary_id` (per product)
- **Data Type:** Number
- **Display:** Dropdown select
- **Validation:** Populate based on Template selected
- **Conditions:**
  - Non-editable if user is prescriber
  - Options filtered by class and patient type

### 23. Filling Method
- **Field Name:** `filling_method_id` (per product)
- **Data Type:** Short Text
- **Display:** Dropdown
- **Validation:** Populate based on Template selected
- **Conditions:** Non-editable if user is prescriber

### 24. Calculated Volume
- **Field Name:** `calculated_volume` (per product)
- **Data Type:** Short Text
- **Display:** Auto-calculated, non-editable
- **Calculation:** Auto-fill, calculate, Non-editable
- **Conditions:** Calculated based on dose and product concentration

### 25. Fill Volume
- **Field Name:** `fill_volume` (per product)
- **Data Type:** Short Text
- **Display:** Auto-calculated, non-editable
- **Calculation:** Auto-fill, calculate, Non-editable
- **Conditions:** Calculated volume for filling

### 26. Osmolarity (per product)
- **Field Name:** `osmolarity` (per product)
- **Data Type:** Number (Decimal)
- **Display:** Read-only field showing formulary osmolarity
- **Unit:** mOsm/L
- **Validation:** Auto-filled from formulary
- **Source:** `formulary.osmolarity`
- **Conditions:** 
  - Displayed in substances table
  - Updated when product/formulary is selected
  - Used in total bag osmolarity calculation
- **Notes:** Individual product osmolarity value

### 27. Additional Dose
- **Field Name:** `additional_dose` (per product)
- **Data Type:** Number
- **Display:** Number input
- **Validation:** 
  - Only enable for substances if premixed standard selected and additional dose is enabled on template
  - Editable
- **Conditions:**
  - Disable if Order Type: Batch Production
- **Notes:** Extra dose beyond standard template dose

### 28. Additional Dose Units
- **Field Name:** `additional_dose_units` (per product)
- **Data Type:** Number
- **Display:** Dropdown or label
- **Validation:**
  - Only enable for substances if premixed standard selected and additional dose is enabled on template
  - Editable
- **Conditions:**
  - Disable if Order Type: Batch Production

### 29. Max Allowed Limit
- **Field Name:** `max_allowed_limit` (per product)
- **Data Type:** Number
- **Display:** Read-only field
- **Validation:**
  - Only enable for substances if premixed standard selected and additional dose is enabled on template
  - Editable
- **Conditions:**
  - Disable if Order Type: Batch Production

### 30. Max Allowed Limit Units
- **Field Name:** `max_allowed_limit_units` (per product)
- **Data Type:** Number
- **Display:** Label
- **Validation:**
  - Only enable for substances if premixed standard selected and additional dose is enabled on template
  - Editable
- **Conditions:**
  - Disable if Order Type: Batch Production

---

## Infusion Configuration

### 31. Vascular Access
- **Field Name:** `vascular_access_id`
- **Data Type:** Number
- **Display:** Dropdown select (simple-select)
- **Validation:** Required for patient-specific orders
- **Options:** Filtered by `patient_type_id` from osmolarities table
- **Conditions:**
  - Mandatory
  - Look up value from vascular access table
  - Disable if Order Type: Batch Production
  - **IMPORTANT:** Only shows vascular accesses that have osmolarity limits defined for the patient's type
- **Notes:** Critical for osmolarity limit determination

### 32. Enteral Product
- **Field Name:** `formulary_id`
- **Data Type:** Number
- **Display:** Dropdown select
- **Validation:** Required for patient-specific orders
- **Options:** Filtered by patient type
- **Conditions:**
  - Lookup value from Formulary/Product table where is Enteral is Yes
  - Disable if Order Type: Batch Production

### 33. Enteral Product Dose per day (mL)
- **Field Name:** `enteral_dose`
- **Data Type:** Number (Float)
- **Display:** Number input
- **Validation:** Required for patient-specific orders
- **Conditions:**
  - Disable if Order Type: Batch Production

### 34. Infusion Duration Type
- **Field Name:** `infusion_duration_type`
- **Data Type:** String (Short Text)
- **Display:** Dropdown select
- **Options:**
  - `Continuous`
  - `Cyclic`
- **Validation:** Required for patient-specific orders
- **Conditions:**
  - Lookup Values: Continuous or Cyclic
  - Disable if Order Type: Batch Production

### 35. TPN Infusion Duration (hours)
- **Field Name:** `tpn_infusion_duration_hours`
- **Data Type:** Number (Integer)
- **Display:** Number input
- **Validation:** Required for patient-specific orders
- **Conditions:**
  - Disable if Order Type: Batch Production
  - Disable if Infusion Type is NOT "2 in 1"
- **Notes:** Only shown when TPN Infusion Type is "2 in 1"

### 36. Lipid Infusion Duration (hours)
- **Field Name:** `lipid_infusion_duration_hours`
- **Data Type:** Number (Integer)
- **Display:** Number input
- **Validation:** Required for patient-specific orders
- **Conditions:**
  - Disable if Order Type: Batch Production

### 37. TPN Infusion Type
- **Field Name:** `tpn_infusion_type`
- **Data Type:** String (Short Text)
- **Display:** Dropdown select
- **Options:**
  - `2 in 1` - TPN and lipids infused separately
  - `3 in 1` - TPN and lipids combined
- **Validation:** Required for patient-specific orders
- **Conditions:**
  - Lookup Values: Continuous or Cyclic
  - Disable if Order Type: Batch Production
  - When "2 in 1" is selected, show TPN Infusion Duration field

---

## Calculation Fields

All calculation fields are stored as JSONB/Map and auto-calculated by the frontend.

### 38. Infusion Calculations
- **Field Name:** `infusion_calculations`
- **Data Type:** Map/JSONB
- **Display:** Summary cards
- **Validation:** Auto-calculated, Non-editable
- **Structure:**
  ```json
  {
    "tpnRate": 0,
    "lipidRate": 0,
    "totalFluids": 0,
    "customTpnRate": 0
  }
  ```
- **Calculations:**
  - **TPN Rate (mL/hr):** `total_fluids / tpn_infusion_duration_hours`
  - **Lipid Rate (mL/hr):** `lipid_volume / lipid_infusion_duration_hours`
  - **Total Fluids:** Sum of all product volumes

### 39. Nutritional Calculations
- **Field Name:** `nutritional_calculations`
- **Data Type:** Map/JSONB
- **Display:** Summary cards
- **Validation:** Auto-calculated, Non-editable
- **Structure:**
  ```json
  {
    "gir": 0,
    "aminoAcidPercent": 0,
    "dextrosePercent": 0,
    "fatInfusionRate": 0,
    "osmolarity": 0
  }
  ```
- **Calculations:**
  - **GIR (mg/kg/min):** `(dextrose_grams * 1000) / (dosing_weight * infusion_hours * 60)`
  - **Amino Acid %:** `(amino_acid_grams / total_volume) * 100`
  - **Dextrose %:** `(dextrose_grams / total_volume) * 100`
  - **Fat Infusion Rate (g/kg/day):** `lipid_grams / dosing_weight`
  - **Osmolarity (mOsm/L):** `(total_osmoles / total_volume_L) * 1000`

### 40. Electrolyte Summary
- **Field Name:** `electrolyte_summary`
- **Data Type:** Map/JSONB
- **Display:** Summary cards
- **Validation:** Auto-calculated, Non-editable
- **Structure:**
  ```json
  {
    "sodium": 0,
    "potassium": 0,
    "calcium": 0,
    "magnesium": 0,
    "phosphate": 0,
    "chloride": 0,
    "acetate": 0
  }
  ```
- **Calculation:** Sum of each electrolyte from all products

### 41. Nutritional Summary
- **Field Name:** `nutritional_summary`
- **Data Type:** Map/JSONB
- **Display:** Summary cards (Energy Summary)
- **Validation:** Auto-calculated, Non-editable
- **Structure:**
  ```json
  {
    "proteinEnergy": 0,
    "dextroseEnergy": 0,
    "lipidEnergy": 0,
    "totalEnergy": 0,
    "nitrogen": 0,
    "nonProteinCalories": 0,
    "nonProteinCaloriesToNitrogenRatio": 0,
    "lipidToTotalEnergyRatio": 0
  }
  ```
- **Calculations:**
  - **Protein Energy (kcal):** `protein_grams * 4`
  - **Dextrose Energy (kcal):** `dextrose_grams * 3.4`
  - **Lipid Energy (kcal):** `lipid_grams * 9`
  - **Total Energy:** Sum of protein, dextrose, and lipid energy
  - **Nitrogen (g):** `protein_grams * 0.16`
  - **Non-Protein Calories:** `dextrose_energy + lipid_energy`
  - **NPC:N Ratio:** `non_protein_calories / nitrogen`
  - **Lipid to Total Energy %:** `(lipid_energy / total_energy) * 100`

### 42. Calculated At
- **Field Name:** `calculated_at`
- **Data Type:** UTC DateTime
- **Display:** Hidden
- **Validation:** Auto-set when calculations run
- **Conditions:** Timestamp of when calculations were performed

---

## Osmolarity Management

### 43. Total Bag Osmolarity
- **Field Name:** Calculated from `nutritional_calculations.osmolarity`
- **Data Type:** Number (Decimal)
- **Display:** Summary cards - Nutritional Values section
- **Unit:** mOsm/L
- **Validation:** Auto-calculated, Non-editable
- **Calculation:**
  ```
  total_osmoles = Σ(product.osmolarity × product.volume)
  total_volume_L = Σ(product.volume) / 1000
  osmolarity = (total_osmoles / total_volume_L) * 1000
  ```
- **Conditions:**
  - Displayed in real-time as products are selected/changed
  - Color-coded based on osmolarity limits
- **Notes:** Critical for patient safety

### 44. Maximum Allowed Osmolarity
- **Field Name:** From `osmolarity_limits` (preloaded)
- **Data Type:** Number (Decimal)
- **Display:** Summary cards - Nutritional Values section
- **Unit:** mOsm/L
- **Source:** `osmolarities` table filtered by `patient_type_id` and `vascular_access_id`
- **Validation:** Lookup from database
- **Conditions:**
  - Displayed when template is loaded
  - Updates when vascular access changes
  - Shows alert type (Soft/Hard)
- **Notes:** Determines if order can proceed

### 45. Osmolarity Alert
- **Field Name:** `osmolarity_alert`
- **Data Type:** Map/JSONB
- **Display:** Alert banner and modal
- **Validation:** Auto-calculated
- **Structure:**
  ```json
  {
    "exceeds": true/false,
    "limit": 900,
    "calculated": 1050,
    "exceeds_limit": 150,
    "alert_type": "Soft" or "Hard",
    "patient_type_id": 1,
    "vascular_access_id": 2,
    "checked_at": "2026-04-05T03:00:00Z",
    "comments": "Override reason",
    "overridden_at": "2026-04-05T03:05:00Z",
    "user_id": 123
  }
  ```
- **Conditions:**
  - **Soft Alert:** Shows warning, requires comments to proceed
  - **Hard Alert:** Blocks order submission entirely
  - Alert shown when `calculated > limit`

### 46. Osmolarity Override Comments
- **Field Name:** Part of `osmolarity_alert.comments`
- **Data Type:** Text
- **Display:** Modal textarea
- **Validation:** Required for soft limit override
- **Conditions:**
  - Only shown when soft limit is exceeded
  - Must be non-empty to proceed
  - Stored with osmolarity alert data

---

## Premixed Bag Fields

### 47. Using Premixed Bag
- **Field Name:** `using_premixed_bag`
- **Data Type:** Yes/No (Boolean)
- **Display:** Checkbox/toggle
- **Default:** `false`
- **Validation:** Optional
- **Conditions:**
  - If yes, enable bottom 2 fields (if enabled only print labels, not send to compunder)
  - Disable if Order Type: Batch Production

### 48. Pre-Mixed Bag Batch Number
- **Field Name:** `premixed_bag_batch_number`
- **Data Type:** Date/Time
- **Display:** Text input
- **Validation:** Optional
- **Conditions:**
  - Only enabled if `using_premixed_bag` is true
  - Blank editable

### 49. Pre-Mixed Bag Expiry Number
- **Field Name:** `premixed_bag_expiry`
- **Data Type:** Date/Time
- **Display:** Date/time picker
- **Validation:** Optional
- **Conditions:**
  - Only enabled if `using_premixed_bag` is true
  - Blank editable

---

## Field Validations & Conditions

### Always Required Fields
1. `bag_id` - Auto-generated
2. `order_type` - Must be selected
3. `order_date` - Auto-filled
4. `template_id` - Must select template

### Required for Patient-Specific Orders Only
(Disabled/Optional for Batch Production)
1. `vascular_access_id`
2. `enteral_dose`
3. `tpn_infusion_type`
4. `infusion_duration_type`
5. `tpn_infusion_duration_hours` (if TPN type is "2 in 1")
6. `lipid_infusion_duration_hours`
7. `dosing_weight`

### Conditional Display Rules

#### TPN Infusion Duration Hours
- **Show when:** `tpn_infusion_type === "2_in_1"`
- **Hide when:** `tpn_infusion_type === "3_in_1"`

#### Additional Dose Fields
- **Show when:** 
  - Premixed standard template is selected
  - Additional dose is enabled on template
- **Hide when:** `order_type === "Batch Production"`

#### Premixed Bag Fields
- **Show when:** `using_premixed_bag === true`
- **Hide when:** `order_type === "Batch Production"`

#### Vascular Access Options
- **Filter:** Only show vascular accesses that have osmolarity limits defined for the patient's `patient_type_id` in the `osmolarities` table

#### Template Options
- **Filter:** Only show templates where `template.patient_type_id === admission.patient_type_id`

#### Formulary Options
- **Filter:** Only show formularies where patient type matches

---

## Calculation Formulas

### Infusion Rate Calculations

#### TPN Rate (mL/hr)
```
IF tpn_infusion_type === "3_in_1":
  tpn_rate = total_fluids / tpn_infusion_duration_hours
ELSE IF tpn_infusion_type === "2_in_1":
  tpn_rate = (total_fluids - lipid_volume) / tpn_infusion_duration_hours
```

#### Lipid Rate (mL/hr)
```
lipid_rate = lipid_volume / lipid_infusion_duration_hours
```

#### Total Fluids (mL)
```
total_fluids = Σ(product.volume for all products)
```

### Nutritional Calculations

#### GIR (Glucose Infusion Rate) - mg/kg/min
```
dextrose_mg = dextrose_grams * 1000
time_minutes = infusion_hours * 60
gir = dextrose_mg / (dosing_weight * time_minutes)
```

#### Amino Acid Percentage (%)
```
amino_acid_percent = (amino_acid_grams / total_volume_mL) * 100
```

#### Dextrose Percentage (%)
```
dextrose_percent = (dextrose_grams / total_volume_mL) * 100
```

#### Fat Infusion Rate (g/kg/day)
```
fat_infusion_rate = lipid_grams / dosing_weight
```

### Osmolarity Calculation

#### Total Osmoles (mOsm)
```
total_osmoles = Σ(product.osmolarity * product.volume_L for all products)

Where:
  product.volume_L = product.volume / 1000
  product.osmolarity = from formulary.osmolarity field
```

#### Osmolarity (mOsm/L)
```
total_volume_L = Σ(product.volume) / 1000
osmolarity = (total_osmoles / total_volume_L) * 1000
```

#### Osmolarity Validation
```
IF calculated_osmolarity > osmolarity_limit:
  IF alert_type === "Hard":
    BLOCK order submission
    SHOW error alert
  ELSE IF alert_type === "Soft":
    SHOW warning alert
    REQUIRE comments to proceed
    ALLOW submission with comments
```

### Energy Calculations

#### Protein Energy (kcal)
```
protein_energy = protein_grams * 4
```
**Constant:** 4 kcal/g

#### Dextrose Energy (kcal)
```
dextrose_energy = dextrose_grams * 3.4
```
**Constant:** 3.4 kcal/g

#### Lipid Energy (kcal)
```
lipid_energy = lipid_grams * 9
```
**Constant:** 9 kcal/g (10 kcal/g for 20% lipid emulsion)

#### Total Energy (kcal)
```
total_energy = protein_energy + dextrose_energy + lipid_energy
```

#### Nitrogen (g)
```
nitrogen = protein_grams * 0.16
```
**Constant:** 0.16 (nitrogen factor)

#### Non-Protein Calories (kcal)
```
non_protein_calories = dextrose_energy + lipid_energy
```

#### NPC:N Ratio (Non-Protein Calories to Nitrogen)
```
IF nitrogen > 0:
  npc_n_ratio = non_protein_calories / nitrogen
ELSE:
  npc_n_ratio = 0
```

#### Lipid to Total Energy Ratio (%)
```
IF total_energy > 0:
  lipid_ratio = (lipid_energy / total_energy) * 100
ELSE:
  lipid_ratio = 0
```

### Electrolyte Calculations

#### Total Electrolytes (per type)
```
For each electrolyte (sodium, potassium, calcium, magnesium, phosphate, chloride, acetate):
  total_electrolyte = Σ(product.electrolyte_amount for all products)
```

---

## Data Flow Summary

### 1. Form Initialization
```
1. Load patient and admission data
2. Set patient_type_id from admission
3. Filter vascular_accesses by patient_type_id (from osmolarities table)
4. Filter templates by patient_type_id
5. Filter formularies by patient_type_id
6. Load osmolarity_limits for patient_type_id
```

### 2. Template Selection
```
1. User selects template
2. HTMX loads template products
3. Populate substances table with template products
4. Load osmolarity data for each product from formulary
5. Set default doses and volumes
```

### 3. Product Changes
```
1. User changes product/dose/volume
2. Update product.osmolarity from selected formulary
3. Recalculate all values:
   - Infusion rates
   - Nutritional values
   - Electrolyte totals
   - Energy summary
   - Total bag osmolarity
4. Emit events to update summary cards
```

### 4. Vascular Access Change
```
1. User selects vascular access
2. Lookup osmolarity limit from preloaded data
3. Match by vascular_access_id
4. Update max allowed osmolarity display
5. Validate current osmolarity against new limit
6. Show/hide alerts as needed
```

### 5. Osmolarity Validation
```
1. Calculate total bag osmolarity
2. Compare with osmolarity limit
3. IF exceeds:
   a. Check alert_type
   b. Show appropriate alert (Soft/Hard)
   c. For Soft: require comments
   d. For Hard: block submission
4. Store osmolarity_alert data
```

### 6. Form Submission
```
1. Validate all required fields
2. Check osmolarity status:
   - Hard limit exceeded → BLOCK
   - Soft limit exceeded without comments → BLOCK
   - Otherwise → ALLOW
3. Serialize all calculation data to JSON
4. Include osmolarity_alert data
5. Set calculated_at timestamp
6. Submit to backend
7. Backend validates osmolarity again
8. Create order record
```

---

## Constants Used in Calculations

| Constant | Value | Unit | Usage |
|----------|-------|------|-------|
| Protein Energy | 4 | kcal/g | Energy from protein |
| Dextrose Energy | 3.4 | kcal/g | Energy from dextrose |
| Lipid Energy (10%) | 10 | kcal/g | Energy from 10% lipid emulsion |
| Lipid Energy (20%) | 9 | kcal/g | Energy from 20% lipid emulsion |
| Nitrogen Factor | 0.16 | - | Protein to nitrogen conversion |

---

## Notes & Important Information

### Batch Production vs Patient Specific

**Patient Specific:**
- All patient-related fields required
- Osmolarity validation applies
- Vascular access required
- Dosing weight required
- Infusion parameters required

**Batch Production:**
- Most patient fields optional
- Number of bags becomes important
- No osmolarity validation (no patient/vascular access)
- Simplified workflow

### Osmolarity Safety

**Critical Safety Feature:**
- Osmolarity limits are patient-type and vascular-access specific
- Hard limits CANNOT be overridden
- Soft limits require documented override with comments
- All osmolarity data is stored with the order for audit trail

### Real-Time Calculations

All calculations happen in real-time on the frontend:
- Updates as user types/selects
- No page refresh needed
- Summary cards update via Alpine.js events
- Backend validates on submission

### Data Preloading

To avoid API calls during form interaction:
- Osmolarity limits preloaded on page load
- Filtered by patient_type_id
- Stored in `window.templateData.osmolarityLimits`
- Instant lookup when vascular access changes

---

## References

- **Schema:** `/lib/tpn/hospital/order.ex`
- **Controller:** `/lib/tpn_web/controllers/hospital/orders/orders_controller.ex`
- **Form Template:** `/lib/tpn_web/controllers/hospital/orders/orders_html/order_components/order_components_html/order_form_new.html.heex`
- **Calculations:** `/assets/js/tpn-calculations.js`
- **State Management:** `/assets/js/xData.js`
- **Images:** `/docs/Order-new.png`, `/docs/Order-new-2.png`
- **Excel Calculations:** `/docs/Calculation TPN.xlsx`

---

**End of Documentation**
