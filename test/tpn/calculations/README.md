# Osmolarity Calculation Tests

This directory contains comprehensive tests for the TPN osmolarity calculation and validation system.

## Test Files

### 1. `osmolarity_validation_test.exs`
Tests the core `OsmolarityValidation` module functions:

- **`calculate_total_osmoles/1`**
  - Calculates total osmoles from products data
  - Handles missing osmolarity or volume values
  - Returns zero for empty lists

- **`calculate_osmolarity/2`**
  - Calculates osmolarity (mOsm/L) from total osmoles and volume
  - Handles zero volume (returns 0)
  - Handles zero osmoles

- **`validate_osmolarity/2`**
  - Validates calculated osmolarity against limit record
  - Returns validation result with exceeds flag
  - Handles both Soft and Hard alert types
  - Calculates excess amount when limit exceeded

- **`can_proceed_with_order/2`**
  - Determines if order can proceed based on validation
  - Allows proceeding when within limits
  - Soft limit: allows with comments, blocks without
  - Hard limit: always blocks (even with comments)

- **`get_osmolarity_limit_api/2`**
  - Tests API response structure
  - Returns success/error format

### 2. `order_calculations_test.exs`
Tests the `OrderCalculations` module integration with osmolarity:

- **Osmolarity Calculation**
  - Calculates osmolarity correctly with multiple products
  - Handles zero osmolarity products
  - Handles empty products list
  - Handles nil osmolarity/volume values
  - Calculates with decimal precision

- **Nutritional Calculations**
  - GIR (Glucose Infusion Rate)
  - Amino acid percentage
  - Dextrose percentage
  - Fat infusion rate

- **Electrolyte Summary**
  - Totals for all electrolytes
  - Handles missing contributions

- **Nutritional Summary**
  - Energy values (protein, dextrose, lipid)
  - Nitrogen calculation
  - Kcal per nitrogen ratios

- **Metadata**
  - Includes calculated_at timestamp

### 3. `osmolarity_integration_test.exs`
Integration tests with database interactions:

- **Complete Flow Tests**
  - End-to-end calculation and validation
  - Database retrieval of osmolarity limits
  - Soft limit scenarios (with/without comments)
  - Hard limit scenarios
  - Missing limit handling
  - Multiple limits error handling

- **Edge Cases**
  - Exactly at limit boundary
  - Just above limit boundary
  - Very high osmolarity values
  - Very small osmolarity values
  - Large number of products (50+)
  - Products with zero volume
  - Negative values (defensive programming)

- **API Response Format**
  - Success response structure
  - Error response structure
  - Multiple records error

### 4. `osmolarity_controller_test.exs`
API endpoint tests for the OsmolarityController:

- **GET `/api/v1/osmolarity/limit`**
  - Returns limit when found
  - Returns 404 when not found
  - Returns 400 for missing parameters
  - Returns 422 for multiple limits
  - Handles both Soft and Hard alert types

- **POST `/api/v1/osmolarity/validate`**
  - Validates within limit
  - Validates exceeding soft limit (with/without comments)
  - Validates exceeding hard limit
  - Returns 400 for missing parameters
  - Returns 404 when limit not found
  - Handles decimal osmolarity values
  - Handles string boolean for has_comments

## Running Tests

### Run all osmolarity tests
```bash
mix test test/tpn/calculations/
```

### Run specific test file
```bash
mix test test/tpn/calculations/osmolarity_validation_test.exs
mix test test/tpn/calculations/order_calculations_test.exs
mix test test/tpn/calculations/osmolarity_integration_test.exs
```

### Run API controller tests
```bash
mix test test/tpn_web/controllers/api/v1/osmolarity_controller_test.exs
```

### Run with coverage
```bash
mix test --cover
```

### Run specific test
```bash
mix test test/tpn/calculations/osmolarity_validation_test.exs:7
```

## Test Coverage

The test suite covers:

- ✅ Unit tests for all calculation functions
- ✅ Validation logic for Soft and Hard limits
- ✅ Order proceeding logic with/without comments
- ✅ API endpoint responses (success and error cases)
- ✅ Database integration and retrieval
- ✅ Edge cases and boundary conditions
- ✅ Error handling and defensive programming
- ✅ Decimal precision and floating-point calculations
- ✅ Multiple products scenarios
- ✅ Missing/nil value handling

## Key Test Scenarios

### Scenario 1: Normal Order Within Limits
```elixir
# Products with total osmolarity = 775 mOsm/L
# Limit = 900 mOsm/L (Soft)
# Result: Can proceed ✅
```

### Scenario 2: Soft Limit Exceeded Without Comments
```elixir
# Calculated osmolarity = 1000 mOsm/L
# Limit = 900 mOsm/L (Soft)
# Comments = false
# Result: Cannot proceed ❌
```

### Scenario 3: Soft Limit Exceeded With Comments
```elixir
# Calculated osmolarity = 1000 mOsm/L
# Limit = 900 mOsm/L (Soft)
# Comments = true
# Result: Can proceed with warning ⚠️
```

### Scenario 4: Hard Limit Exceeded
```elixir
# Calculated osmolarity = 1500 mOsm/L
# Limit = 1200 mOsm/L (Hard)
# Comments = true/false
# Result: Cannot proceed ❌
```

## Formula Reference

### Total Osmoles
```
total_osmoles = Σ(product.osmolarity × product.volume)
```

### Osmolarity (mOsm/L)
```
osmolarity = (total_osmoles / total_volume_mL) × 1000
```

### Validation
```
exceeds = calculated_osmolarity > limit_osmolarity
exceeds_limit = calculated_osmolarity - limit_osmolarity (if exceeds)
```

## Database Schema

### osmolarities table
- `osmolarity` (decimal) - The osmolarity limit value
- `alert_type` (string) - "Soft" or "Hard"
- `patient_type_id` (integer) - FK to patient_types
- `vascular_access_id` (integer) - FK to vascular_accesses
- `user_id` (integer) - FK to users

### Unique Constraint
Each combination of `patient_type_id` and `vascular_access_id` should have only one osmolarity limit.

## Test Data Setup

Tests use factory-like helper functions:
- `insert_patient_type/1`
- `insert_vascular_access/1`
- `insert_osmolarity/1`

These create test records in the database with proper associations.

## Assertions Used

- `assert` - Basic boolean assertions
- `assert_in_delta` - Floating-point comparisons with tolerance
- `Decimal.equal?/2` - Exact decimal comparisons
- `json_response/2` - API response validation

## Notes

- All tests use `async: true` where possible for parallel execution
- Database tests use SQL sandbox for isolation
- Decimal library used for precise financial/medical calculations
- Tests follow ExUnit conventions and best practices
