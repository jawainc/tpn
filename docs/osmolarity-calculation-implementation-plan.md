# TPN Order Form Osmolarity Calculation Implementation Plan

## Task Summary
Update and fix the order form to implement osmolarity calculations and validation based on patient type and vascular access. The system should calculate total bag osmolarity from product osmolarities, compare against configured limits, and alert users with appropriate soft/hard warnings.

---

## Current State Analysis

### ✅ Already Implemented

#### 1. Database Schema
- `osmolarities` table with `alert_type` (Soft/Hard), `osmolarity`, `vascular_access_id`, `patient_type_id`
- `osmolarities_view` joining with vascular_accesses, patient_types, and users
- `formularies` table has `osmolarity` field (decimal, required, default 0.0)
- Migration `20260328164038_add_alert_type_to_osmolarities.exs` completed
- Migration `20260328163953_add_osmolarity_to_formularies.exs` completed

#### 2. Backend Services (Elixir)
- **`Tpn.Calculations.OsmolarityValidation`** module:
  - `get_osmolarity_limit/2` - retrieves limits by patient_type and vascular_access
  - `validate_osmolarity/2` - validates calculated vs limit
  - `can_proceed_with_order/2` - determines if order can proceed (Soft/Hard alerts)
  - `calculate_total_osmoles/1` - calculates total osmoles from products
  - `calculate_osmolarity/2` - calculates osmolarity (mOsm/L) from osmoles and volume
  
- **`TpnWeb.Api.V1.OsmolarityController`** with API endpoints:
  - `GET /api/v1/osmolarity/limit` - fetch osmolarity limit
  - `POST /api/v1/osmolarity/validate` - validate osmolarity
  
- **`Tpn.Calculations.OrderCalculations`** module:
  - Calculates osmolarity in nutritional calculations
  - Uses `calculate_osmolarity/2` from OsmolarityValidation

#### 3. Frontend JavaScript Implementation
- **`assets/js/tpn-calculations.js`** - Comprehensive calculation module:
  - ✅ `calculateTotalOsmoles(productsData)` - calculates total osmoles from products
  - ✅ `calculateOsmolarity(totalOsmoles, totalVolumeMl)` - calculates osmolarity (mOsm/L)
  - ✅ `calculateInfusionRates()` - TPN rate, lipid rate, total fluids
  - ✅ `calculateNutritionalValues()` - GIR, amino acid %, dextrose %, fat rate, **osmolarity**
  - ✅ `calculateElectrolyteTotals()` - sodium, potassium, calcium, etc.
  - ✅ `calculateNutritionalSummary()` - energy values, nitrogen, ratios
  - ✅ `validateOsmolarity()` - validates against limits
  - ✅ `canProceedWithOrder()` - determines if order can proceed
  - ✅ `prepareProductsData()` - includes `osmolarity` field from products

- **`assets/js/xData.js`** - Alpine.js component for order form:
  - ✅ `calculateAllValues()` - calls TpnCalculations module
  - ✅ `checkOsmolarity()` - fetches osmolarity limit from API
  - ✅ `fetchOsmolarityLimit()` - API call to get limit
  - ✅ `validateCurrentOsmolarity()` - validates calculated osmolarity
  - ✅ `updateProductCalculations()` - updates product osmolarity from formulary
  - ✅ `emitCalculationEvents()` - emits events for summary cards
  - ✅ State management for osmolarity alerts and limits

#### 4. Summary Cards Component
- **`summary_cards.html.heex`** - Dynamic summary display:
  - ✅ Listens for `order-calculations-updated` events
  - ✅ Displays infusion calculations (TPN rate, lipid rate, total fluids)
  - ✅ Displays nutritional values (GIR, amino acid %, dextrose %, fat rate, **osmolarity**)
  - ✅ Displays electrolyte summary (7 electrolytes)
  - ✅ Displays energy summary (protein, dextrose, lipid energy, ratios)
  - ✅ Real-time updates via Alpine.js event listeners
  - ⚠️ **Osmolarity status** uses hardcoded thresholds (900, 1200) - NOT patient-specific limits

#### 5. Order Schema & Controller
- `orders` table has `osmolarity_alert` field (map/jsonb)
- Order changeset accepts osmolarity_alert data
- OrdersController validates osmolarity alerts before creating orders

---

### ❌ Missing/Incomplete Issues

#### 1. **Formulary Osmolarity NOT Displayed in UI**
- ❌ Substances table in order form does NOT show osmolarity column
- ❌ Users cannot see individual product osmolarity values
- ⚠️ Osmolarity IS included in calculations but not visible to users

#### 2. **Maximum Allowed Osmolarity NOT Displayed**
- ❌ Summary cards do NOT show the maximum allowed osmolarity limit
- ❌ No display of patient type and vascular access context
- ❌ No indication of alert type (Soft/Hard)
- ⚠️ Osmolarity status uses hardcoded thresholds instead of actual limits from database

#### 3. **Osmolarity Calculation Issues**
**Current Implementation:**
```javascript
// Line 213-214 in tpn-calculations.js
const totalOsmoles = calculateTotalOsmoles(productsData);
const osmolarity = bagVolume > 0 ? (totalOsmoles / bagVolume) * 1000 : 0;
```

**Potential Issues:**
- ✅ Formula is correct: `osmolarity = (total_osmoles / volume_L) * 1000`
- ⚠️ Uses `bagVolume` from template, not actual total volume from products
- ⚠️ Need to verify if this matches backend calculation logic

**Backend Calculation:**
```elixir
# lib/tpn/calculations/order_calculations.ex (line 271-276)
defp calculate_osmolarity(products_data, _template) do
  total_osmoles = calculate_total_osmoles(products_data)
  total_volume = calculate_total_volume(products_data)
  OsmolarityValidation.calculate_osmolarity(total_osmoles, total_volume)
end
```

**Discrepancy Found:**
- ❌ **Frontend uses `bagVolume` from template**
- ❌ **Backend uses `total_volume` from products**
- ❌ **This may cause calculation mismatch!**

#### 4. **Product Osmolarity Not Populated from Formulary**
- ⚠️ `updateProductCalculations()` sets `product.osmolarity = formulary.osmolarity`
- ❌ But formulary data may not include osmolarity in JSON response
- ❌ Need to verify formulary serialization includes osmolarity

#### 5. **Alert System Incomplete**
- ❌ No visible alert banner when osmolarity exceeds limits
- ❌ No modal/dialog for soft limit override with comments
- ❌ No blocking UI for hard limit violations
- ⚠️ Logic exists in xData.js but no UI components

#### 6. **Summary Cards Osmolarity Status Issues**
```javascript
// Lines 75-85 in summary_cards.html.heex
getOsmolarityClass(value) {
  if (value <= 900) return 'text-green-600';
  if (value <= 1200) return 'text-yellow-600';
  return 'text-red-600';
}
```
- ❌ **Hardcoded thresholds (900, 1200) are NOT patient-specific**
- ❌ Should use actual osmolarity limit from database
- ❌ Should show alert type (Soft/Hard) instead of generic status

#### 7. **Event Name Mismatch**
- Summary cards listen for `calculations-updated` event
- xData.js emits `order-calculations-updated` event
- ⚠️ Event names don't match - may cause summary cards not to update

#### 8. **Missing Calculations**
After reviewing both frontend and backend:
- ✅ All major calculations are implemented
- ✅ Infusion rates calculated correctly
- ✅ Nutritional values calculated correctly
- ✅ Electrolyte totals calculated correctly
- ✅ Energy summary calculated correctly
- ✅ Osmolarity calculation logic exists

**However:**
- ❌ Frontend/Backend osmolarity calculation uses different volumes (discrepancy)
- ❌ No calculation for "Total Allowed Osmolarity" display
- ❌ No calculation for osmolarity safety margin (limit - calculated)

---

## Implementation Plan

### Phase 0: Fix Critical Issues in Current Implementation
**Status: URGENT - Must Fix First**

#### 0.1 Fix Osmolarity Calculation Volume Discrepancy
**Issue:** Frontend uses `bagVolume` from template, Backend uses `total_volume` from products

**Decision needed:** Which approach is correct?
- Option A: Use `bagVolume` (template fluids) - assumes all products fit in bag
- Option B: Use `total_volume` (sum of product volumes) - actual volume used
- **Recommended:** Use `total_volume` from products for accuracy

**Files to modify:**
- `assets/js/tpn-calculations.js` (line 214)
  - Change from: `const osmolarity = bagVolume > 0 ? (totalOsmoles / bagVolume) * 1000 : 0;`
  - Change to: `const totalVolume = calculateTotalVolume(productsData);`
  - Then: `const osmolarity = totalVolume > 0 ? (totalOsmoles / totalVolume) * 1000 : 0;`

#### 0.2 Fix Event Name Mismatch
**Issue:** Summary cards listen for `calculations-updated`, xData emits `order-calculations-updated`

**Files to modify:**
- `lib/tpn_web/controllers/hospital/orders/orders_html/order_components/order_components_html/summary_cards.html.heex`
  - Line 43: Change `calculations-updated` to `order-calculations-updated`
  - OR update xData.js to emit both events for backward compatibility

#### 0.3 Fix Summary Cards Osmolarity Status
**Issue:** Hardcoded thresholds (900, 1200) instead of patient-specific limits

**Files to modify:**
- `summary_cards.html.heex`
  - Add `osmolarityLimit` to Alpine.js state
  - Listen for osmolarity limit updates from xData
  - Update `getOsmolarityClass()` and `getOsmolarityStatus()` to use actual limit
  - Display limit value and alert type

---

### Phase 1: Backend - Verify and Enhance
**Status: Mostly Complete - Needs Verification**

#### 1.1 Verify OrderCalculations Module
- [x] `calculate_osmolarity/2` includes formulary osmolarity ✅
- [x] `calculate_total_osmoles/1` exists in OsmolarityValidation ✅
- [x] Osmolarity calculation uses product volume and formulary osmolarity ✅
- [ ] Verify backend calculation matches frontend after Phase 0 fix

**Files to check:**
- `lib/tpn/calculations/order_calculations.ex`
- `lib/tpn/calculations/osmolarity_validation.ex`

#### 1.2 Verify API Endpoints and Routes
- [x] `/api/v1/osmolarity/limit` endpoint exists ✅
- [x] `/api/v1/osmolarity/validate` endpoint exists ✅
- [ ] Verify routes are registered in router
- [ ] Test API endpoints return correct data

**Files to check:**
- `lib/tpn_web/api/v1/osmolarity_controller.ex`
- `lib/tpn_web/router.ex`

#### 1.3 Verify Formulary Serialization
- [x] Formulary schema includes `:osmolarity` in Jason.Encoder ✅
- [ ] Verify formulary data in order form includes osmolarity
- [ ] Check template_products controller action serializes formulary osmolarity

**Files to check:**
- `lib/tpn/lab/formulary.ex`
- `lib/tpn_web/controllers/hospital/orders/orders_controller.ex` (formularies method)

---

### Phase 2: Frontend - Display Formulary Osmolarity in Substances Table
**Status: Not Started**

#### 2.1 Add Osmolarity Column to Substances Table
- [ ] Add "Osmolarity (mOsm/L)" column header in template_products.html.heex
- [ ] Display `product.osmolarity` value for each product row
- [ ] Show osmolarity from formulary when product is selected
- [ ] Update column layout (currently 5 columns, add 6th for osmolarity)

**Files to modify:**
- `lib/tpn_web/controllers/hospital/orders/orders_html/template_products.html.heex`
  - Around line 214: Add osmolarity column after fill_volume
  - Display: `<span x-text="product.osmolarity || '0.00'"></span>`

#### 2.2 Ensure Osmolarity Populated from Formulary
- [ ] Verify `handleProductChange()` in xData.js populates osmolarity
- [ ] Ensure formulary data includes osmolarity field
- [ ] Update `updateProductCalculations()` to set osmolarity from formulary

**Files to modify:**
- `assets/js/xData.js`
  - Line 568-583: Verify `handleProductChange()` sets product.osmolarity
  - Line 321-336: Verify `updateProductCalculations()` updates osmolarity

---

### Phase 3: Update Summary Cards - Display Max Allowed Osmolarity
**Status: Not Started**

#### 3.1 Add Osmolarity Limit Display to Summary Cards
- [ ] Add `osmolarityLimit` state to summary_cards Alpine.js component
- [ ] Listen for `osmolarity-limit-fetched` event from xData
- [ ] Display "Max Allowed Osmolarity" field in Nutritional Values card
- [ ] Show limit value, alert type (Soft/Hard), patient type, and vascular access

**Files to modify:**
- `summary_cards.html.heex`
  - Add osmolarityLimit to Alpine.js state
  - Add event listener for osmolarity limit updates
  - Add display section for max allowed osmolarity
  - Update osmolarity status to use actual limit instead of hardcoded thresholds

#### 3.2 Emit Osmolarity Limit Event from xData
- [ ] Update `fetchOsmolarityLimit()` to emit event when limit is fetched
- [ ] Emit `osmolarity-limit-fetched` event with limit data
- [ ] Update on vascular access or patient type change

**Files to modify:**
- `assets/js/xData.js`
  - Line 237-254: Update `fetchOsmolarityLimit()` to emit event
  - Add event emission after successful API response

---

### Phase 4: Frontend - Osmolarity Alert UI Components
**Status: Not Started**

#### 4.1 Create Alert Banner Component
- [ ] Create alert banner that shows when osmolarity exceeds limits
- [ ] Display different styles for Soft (warning) vs Hard (error) alerts
- [ ] Show calculated osmolarity, limit, and excess amount
- [ ] Include patient type and vascular access information

**Files to create/modify:**
- `lib/tpn_web/controllers/hospital/orders/orders_html/order_components/order_components_html/osmolarity_alert.html.heex` (new)
- `lib/tpn_web/controllers/hospital/orders/orders_html/order_form_new.html.heex` (include alert component)

#### 4.2 Create Soft Limit Override Modal
- [ ] Create modal dialog for soft limit override
- [ ] Include comment textarea (required for soft limit override)
- [ ] Show osmolarity details and warning message
- [ ] Add "Proceed with Override" and "Cancel" buttons

**Files to create/modify:**
- `lib/tpn_web/controllers/hospital/orders/orders_html/order_components/order_components_html/osmolarity_override_modal.html.heex` (new)
- `assets/js/xData.js` - connect modal to state

#### 4.3 Update xData to Show/Hide Alerts
- [ ] Update `validateCurrentOsmolarity()` to trigger UI alerts
- [ ] Set `showOsmolarityAlert` state when limit exceeded
- [ ] Populate alert data for display in banner
- [ ] Show override modal for soft limits

**Files to modify:**
- `assets/js/xData.js`
  - Line 257-279: Update `validateCurrentOsmolarity()`

---

### Phase 5: Frontend - Block Order Submission Based on Osmolarity
**Status: Not Started**

#### 5.1 Disable Submit Button Logic
- [ ] Disable "Create Order" button when hard limit exceeded
- [ ] Disable "Create Order" button when soft limit exceeded without comments
- [ ] Enable button when within limits or soft limit with comments
- [ ] Add visual indicator (disabled state, tooltip)

**Files to modify:**
- `lib/tpn_web/controllers/hospital/orders/orders_html/order_form_new.html.heex`
- `assets/js/xData.js`

#### 5.2 Form Submission Validation
- [ ] Before form submit, validate osmolarity one final time
- [ ] Include osmolarity_alert data in form submission
- [ ] Add hidden field for osmolarity_alert JSON data
- [ ] Backend validation already exists in OrdersController ✅

**Files to modify:**
- `assets/js/xData.js`
  - Line 465-497: Update `saveCalculationsToForm()`
  - Add osmolarity_alert to form data
- `lib/tpn_web/controllers/hospital/orders/orders_html/order_form_new.html.heex`
  - Add hidden field for osmolarity_alert

#### 5.3 Handle Form Submission with Osmolarity Override
- [ ] Update `submitOrderWithOsmolarityOverride()` to include all data
- [ ] Set osmolarity_alert hidden field before form submission
- [ ] Include override timestamp and user ID

**Files to modify:**
- `assets/js/xData.js`
  - Line 299-319: Verify `submitOrderWithOsmolarityOverride()`

---

### Phase 6: Testing & Bug Fixes
**Status: Not Started**

#### 6.1 Test Osmolarity Calculation Accuracy
- [ ] Test with single product - verify osmolarity calculation
- [ ] Test with multiple products - verify total osmolarity
- [ ] Compare frontend calculation with backend calculation
- [ ] Verify volume calculation matches (after Phase 0 fix)
- [ ] Test with products having zero osmolarity

#### 6.2 Test Osmolarity Validation Scenarios
- [ ] Test with no osmolarity limit configured (should allow order)
- [ ] Test with osmolarity below limit (should allow order)
- [ ] Test with osmolarity exceeding soft limit without comments (should block)
- [ ] Test with osmolarity exceeding soft limit with comments (should allow)
- [ ] Test with osmolarity exceeding hard limit (should always block)
- [ ] Test vascular access change updates limit
- [ ] Test patient type change updates limit

#### 6.3 Test UI Components
- [ ] Verify summary cards update in real-time
- [ ] Verify osmolarity limit displays correctly
- [ ] Verify alert banner shows for limit violations
- [ ] Verify soft limit override modal works
- [ ] Verify submit button disables/enables correctly
- [ ] Verify formulary osmolarity displays in substances table

#### 6.4 Edge Cases
- [ ] Handle missing formulary osmolarity values (default to 0)
- [ ] Handle division by zero in osmolarity calculation
- [ ] Handle multiple osmolarity limits for same patient type/vascular access
- [ ] Handle no products selected (osmolarity = 0)
- [ ] Handle template change after osmolarity validation
- [ ] Handle product removal after limit exceeded

#### 6.5 Review Batched Orders
- [ ] Analyze batched orders implementation (mentioned in task notes)
- [ ] Determine if osmolarity validation applies to batch orders
- [ ] Fix any bugs in batch order calculations
- [ ] Test batch production order type

**Files to review:**
- Order form for batch production orders
- `lib/tpn_web/controllers/hospital/orders/orders_controller.ex`
- `lib/tpn/hospital/order.ex` (validate_custom_required for batch orders)

---

## Data Flow Diagram

```
1. User selects template
   ↓
2. Frontend loads template products with formulary data (including osmolarity)
   ↓
3. Frontend fetches osmolarity limit (patient_type_id + vascular_access_id)
   ↓
4. User selects/changes products and doses
   ↓
5. Frontend calculates total bag osmolarity:
   - For each product: osmoles = formulary.osmolarity × product.volume
   - Total osmoles = sum of all product osmoles
   - Total osmolarity = total_osmoles / total_volume
   ↓
6. Frontend validates against limit:
   - If calculated > limit → Alert
   - Check alert_type (Soft/Hard)
   - Update UI accordingly
   ↓
7. User attempts to submit order
   ↓
8. Frontend validates:
   - Hard limit exceeded → Block submission
   - Soft limit exceeded without comments → Block submission
   - Otherwise → Allow submission
   ↓
9. Backend validates osmolarity_alert data
   ↓
10. Order created with osmolarity_alert stored
```

---

## Files to Create/Modify

### Backend (Elixir)
1. `lib/tpn/calculations/order_calculations.ex` - Enhance osmolarity calculation
2. `lib/tpn/calculations/osmolarity_validation.ex` - Verify/enhance validation logic
3. `lib/tpn_web/api/v1/osmolarity_controller.ex` - Verify API endpoints
4. `lib/tpn_web/router.ex` - Verify routes registered

### Frontend (HTML/JavaScript)
1. `assets/js/xData.js` - Add osmolarity calculation and validation logic
2. `lib/tpn_web/controllers/hospital/orders/orders_html/template_products.html.heex` - Display osmolarity fields
3. `lib/tpn_web/controllers/hospital/orders/orders_html/order_form_new.html.heex` - Add alerts and validation

### Views/Templates
1. Summary cards component - Add osmolarity display
2. Substances table - Add osmolarity column

---

---

## Critical Issues Found - Summary

### 🔴 High Priority Issues (Must Fix)
1. **Osmolarity Calculation Volume Discrepancy**
   - Frontend uses `bagVolume` from template
   - Backend uses `total_volume` from products
   - **Impact:** Calculations may not match between frontend and backend
   - **Fix:** Update frontend to use `total_volume` from products

2. **Event Name Mismatch**
   - Summary cards listen for `calculations-updated`
   - xData emits `order-calculations-updated`
   - **Impact:** Summary cards may not update in real-time
   - **Fix:** Align event names

3. **Hardcoded Osmolarity Thresholds**
   - Summary cards use hardcoded values (900, 1200)
   - Should use patient-specific limits from database
   - **Impact:** Incorrect osmolarity status display
   - **Fix:** Use actual limits from API

### 🟡 Medium Priority Issues (Should Fix)
4. **Formulary Osmolarity Not Displayed**
   - Users cannot see individual product osmolarity values
   - **Impact:** Poor user experience, lack of transparency
   - **Fix:** Add osmolarity column to substances table

5. **Max Allowed Osmolarity Not Displayed**
   - Summary cards don't show the limit
   - **Impact:** Users don't know the threshold
   - **Fix:** Add limit display to summary cards

6. **No Alert UI Components**
   - Logic exists but no visible alerts
   - **Impact:** Users not warned about violations
   - **Fix:** Create alert banners and modals

### ✅ What's Working Well
- Backend calculation logic is complete and correct
- Frontend calculation module (tpn-calculations.js) is comprehensive
- API endpoints exist and are functional
- Database schema is properly configured
- Osmolarity validation logic is implemented
- Summary cards component exists and is well-structured

---

## Questions to Resolve

1. **Osmolarity Calculation Volume** ✅ RESOLVED
   - **Decision:** Use `total_volume` from products (sum of product volumes)
   - **Reason:** More accurate than template bag volume
   - **Action:** Update frontend calculation in Phase 0

2. **Vascular Access Selection**: When is vascular_access_id selected in the order form?
   - Need to ensure it's available when fetching osmolarity limit
   - Check order form fields and initialization

3. **Batch Orders**: Do batch production orders require osmolarity validation?
   - Task notes mention bugs in batched orders
   - Order schema has special validation for "Batch Production" type
   - Need to determine if osmolarity applies to batch orders

4. **Multiple Limits**: What happens if multiple osmolarity limits exist for the same patient_type + vascular_access?
   - Current code returns error for multiple records
   - Should there be a unique constraint on the database?

5. **Formulary Osmolarity in JSON**: Is osmolarity included when formularies are serialized?
   - Schema includes it in Jason.Encoder ✅
   - Need to verify in actual API response

---

## Success Criteria

- [x] Osmolarities table and view are properly configured
- [x] Formularies table includes osmolarity field
- [ ] Formulary osmolarity is displayed in order form substances section
- [ ] Total bag osmolarity is calculated and displayed in real-time
- [ ] Maximum allowed osmolarity is displayed based on patient type and vascular access
- [ ] Soft limit alerts are shown with comment field
- [ ] Hard limit alerts block order submission
- [ ] Order submission includes osmolarity_alert data
- [ ] Backend validates osmolarity before creating order
- [ ] All test scenarios pass
- [ ] No bugs in batch order calculations

---

## Notes

- The backend infrastructure is largely complete
- Main work is frontend integration and UI updates
- Need to review `docs/Calculation TPN.xlsx` for exact formulas
- Need to review `docs/order-new.png` and `docs/order-new-2.png` for UI design
- Task mentions analyzing batched orders for bugs - this needs investigation

---

## Next Steps

1. **Wait for approval** before starting implementation
2. Review calculation formulas in Excel file
3. Start with Phase 2 (displaying formulary osmolarity)
4. Progress through phases sequentially
5. Test thoroughly at each phase
