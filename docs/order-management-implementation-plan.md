# TPN Order Management System - Implementation Plan

**Version:** 1.0  
**Date:** April 5, 2026  
**Status:** Planning Phase

---

## Table of Contents

1. [Overview](#overview)
2. [Requirements Summary](#requirements-summary)
3. [User Hierarchy & Access Control](#user-hierarchy--access-control)
4. [Implementation Phases](#implementation-phases)
5. [Technical Architecture](#technical-architecture)
6. [Questions & Decisions](#questions--decisions)
7. [Database Changes](#database-changes)
8. [UI/UX Design](#uiux-design)

---

## Overview

This document outlines the implementation plan for creating a modern order management system with proper user hierarchy and network-based access control. The system will allow users to view, filter, and create TPN orders based on their network access level (Admin, LHN, Facility, or Campus).

---

## Requirements Summary

### Core Requirements

1. **Orders List Page** (`Hospital -> Orders`)
   - Modern, responsive table layout
   - Display orders based on user's network access
   - Network selection fields (conditional based on user role)
   - Support for both bulk and single orders

2. **User Hierarchy & Access Control**
   - **Admin**: See all orders, requires LHN → Facility → Campus selection fields
   - **Facility User**: See facility orders, requires Campus selection field
   - **Campus User**: See only their campus orders, no selection fields needed

3. **Patient Selection Flow**
   - Show admitted patients list with details
   - Filter by user's network access
   - After selection, redirect to existing patient order form

4. **Order Form**
   - Use existing patient order form (already created)
   - Based on `docs/tpn-order-form-fields-documentation.md`

---

## User Hierarchy & Access Control

### Existing Infrastructure

The system already has network hierarchy implemented:

```elixir
# From: lib/tpn_web/helpers/networks.ex
def get_user_network_access(conn) do
  current_user = conn.assigns[:current_user]
  
  cond do
    conn.assigns[:is_admin] ->
      {:ok, %{:lhn_id => nil, :facility_id => nil, :campus_id => nil}}
    
    !is_nil(current_user.campus_id) ->
      {:ok, %{:lhn_id => nil, :facility_id => nil, :campus_id => current_user.campus_id}}
    
    !is_nil(current_user.facility_id) ->
      {:ok, %{:lhn_id => nil, :facility_id => current_user.facility_id, :campus_id => nil}}
    
    !is_nil(current_user.local_health_network_id) ->
      {:ok, %{:lhn_id => current_user.local_health_network_id, :facility_id => nil, :campus_id => nil}}
    
    true ->
      {:error, %{}}
  end
end
```

### Access Control Matrix

| User Type | Network Fields | Can See Orders From | Selection Fields Required |
|-----------|---------------|---------------------|---------------------------|
| **Admin** | None set | All networks | LHN → Facility → Campus |
| **LHN User** | `local_health_network_id` | Entire LHN | Facility → Campus |
| **Facility User** | `facility_id` | Entire Facility | Campus only |
| **Campus User** | `campus_id` | Own campus only | None |

---

## Implementation Phases

### Phase 1: Backend - Data Access Layer

**Estimated Time:** 2-3 hours

#### 1.1 Update Orders Context (`lib/tpn/hospital/orders.ex`)

- [ ] Add `list_orders_for_user/3` function
  - Parameters: `lhn_id`, `facility_id`, `campus_id`
  - Returns orders filtered by network hierarchy
  - Include preloaded associations (patient, admission, campus, facility, lhn)

- [ ] Add `list_orders_with_filters/2` function
  - Support pagination
  - Support status filtering
  - Support date range filtering
  - Support search by patient name, bag_id

- [ ] Create order view query with joins
  ```elixir
  # Pseudo-code structure
  from o in Order,
    join: p in Patient, on: o.patient_id == p.id,
    join: a in Admission, on: o.admission_id == a.id,
    join: c in Campus, on: a.campus_id == c.id,
    join: f in Facility, on: c.facility_id == f.id,
    join: lhn in LocalHealthNetwork, on: f.local_health_network_id == lhn.id
  ```

#### 1.2 Verify Admissions Context

- [ ] Confirm `list_admissions_for_user/3` exists and works
- [ ] Ensure it returns admitted patients only (active admissions)
- [ ] Add necessary preloads (patient, ward, patient_type)

---

### Phase 2: Backend - Controller & Routes

**Estimated Time:** 3-4 hours

#### 2.1 Update OrdersController (`lib/tpn_web/controllers/hospital/orders/orders_controller.ex`)

- [ ] Add `list/2` action for orders listing page
  - Get user network access
  - Load network dropdowns (conditional)
  - Apply filters from params
  - Render orders table

- [ ] Add `select_patient/2` action for patient selection
  - Get admitted patients based on network access
  - Render patient selection view

- [ ] Update existing `admissions/2` action if needed

#### 2.2 Update Router (`lib/tpn_web/router.ex`)

- [ ] Update existing route: `get "/orders", Hospital.OrdersController, :show` (replace content)
- [ ] Add route: `get "/orders/admitted-patients", Hospital.OrdersController, :admitted_patients` (for modal)
- [ ] Keep existing routes for order creation
- [ ] Consider route for bulk order form if needed

---

### Phase 3: Frontend - Orders List Page

**Estimated Time:** 4-5 hours

#### 3.1 Update Orders List Template

**File:** `lib/tpn_web/controllers/hospital/orders/orders_html/show.html.heex` (replace existing)

- [ ] Breadcrumb navigation
- [ ] Page header with two buttons:
  - "Admission Order" button (opens patient selection modal)
  - "Bulk Order" button (opens bulk order form/modal)
  - Refresh icon button (reloads table via HTMX)
- [ ] Filters section
  - Search input (patient name, bag ID)
  - Status filter dropdown
  - Date range picker
- [ ] Orders table with columns:
  - Order Type (Badge: "Patient" or "Bulk")
  - Bag ID
  - Patient Name (for Patient orders, "Batch Production" for Bulk)
  - Order Date
  - Status (Badge: Draft/Pending/Approved/Rejected)
  - Campus
  - Facility
  - Actions (View, Edit for drafts, Copy for approved)
- [ ] Pagination controls
- [ ] Empty state when no orders

#### 3.2 HTMX Integration

- [ ] Network dropdown cascade (LHN → Facility → Campus)
- [ ] Filter changes trigger table reload
- [ ] Pagination via HTMX
- [ ] Search with debounce

#### 3.3 Styling with BasecoatUI

- [ ] Use BasecoatUI table components
- [ ] Status badges with color coding
- [ ] Responsive design (mobile-friendly)
- [ ] Loading states

---

### Phase 4: Frontend - Patient Selection Modal

**Estimated Time:** 3-4 hours

#### 4.1 Create Patient Selection Modal Component

**File:** `lib/tpn_web/controllers/hospital/orders/orders_html/admitted_patients_modal.html.heex`

- [ ] Modal overlay with backdrop
- [ ] Modal header with "Select Patient" title and close button
- [ ] Search/filter bar within modal
- [ ] Patient table or cards with:
  - Patient Name
  - MRN (Medical Record Number)
  - Admission Date
  - Age
  - Ward
  - Patient Type
  - Campus/Facility info
  - "Create Order" button (navigates to order form)
- [ ] Empty state for no admitted patients
- [ ] Loading state while fetching patients

#### 4.2 Modal Integration

- [ ] HTMX trigger from "Admission Order" button
- [ ] Load patients via HTMX: `hx-get="/orders/admitted-patients"`
- [ ] Modal closes on patient selection (navigation)
- [ ] Keyboard support (ESC to close)

---

### Phase 5: Integration & Polish

**Estimated Time:** 2-3 hours

#### 5.1 Navigation Updates

- [ ] Update Hospital menu to link to `/hospital/orders/list`
- [ ] Ensure breadcrumbs work correctly across all pages
- [ ] Add back navigation from patient selection to orders list

#### 5.2 Testing

- [ ] Test as Admin user
- [ ] Test as Facility user
- [ ] Test as Campus user
- [ ] Test network filtering
- [ ] Test order creation flow
- [ ] Test pagination and search
- [ ] Mobile responsiveness testing

#### 5.3 Error Handling

- [ ] Handle no network access scenario
- [ ] Handle no admitted patients
- [ ] Handle no orders found
- [ ] Validation errors

---

## Technical Architecture

### Data Flow

#### Viewing Orders
```
1. User lands on /orders
   ↓
2. System checks user network access
   ↓
3. Load orders based on network access level
   ↓
4. Display orders table (latest first, paginated)
   ↓
5. User can filter, search, sort orders
```

#### Creating Admission Order (Patient Specific)
```
1. User clicks "Admission Order" button
   ↓
2. Open patient selection modal
   ↓
3. Load admitted patients (filtered by user's network access)
   ↓
4. User selects patient
   ↓
5. Navigate to /patients/:patient_id/orders/new (existing form)
   ↓
6. User completes order form and submits
```

#### Creating Bulk Order
```
1. User clicks "Bulk Order" button
   ↓
2. Show bulk order form with network selection (if admin/facility user)
   ↓
3. User selects network (LHN/Facility/Campus based on role)
   ↓
4. User completes bulk order form
   ↓
5. Submit bulk order
```

#### Copying Order
```
1. User clicks "Copy" on approved order
   ↓
2. If Patient order: Open patient selection modal
   If Bulk order: Open bulk order form with pre-filled data
   ↓
3. User selects patient (for patient orders) or modifies bulk order
   ↓
4. Navigate to order form with copied data
```

### Key Components

#### Backend Modules
- `Tpn.Hospital.Orders` - Order queries and business logic
- `Tpn.Hospital.Admissions` - Admission queries
- `TpnWeb.Hospital.OrdersController` - HTTP request handling
- `TpnWeb.Helpers.Networks` - Network access helpers

#### Frontend Templates
- `show.html.heex` - Orders listing page (updated)
- `admitted_patients_modal.html.heex` - Patient selection modal
- `new.html.heex` - Order form (existing, unchanged)

#### Shared Components
- Network selection dropdowns (for bulk orders only)
- Patient selection modal
- Patient cards/rows (in modal)
- Order table rows
- Order type badges (Patient/Bulk)
- Status badges (Draft/Pending/Approved/Rejected)
- Pagination controls
- Refresh button

---

## Questions & Decisions

### 🔴 CRITICAL - Please Answer

#### 1. Route Structure
**Question:** What should be the primary route for the orders list page?

**✅ DECISION:** Replace existing `/orders` page content with new orders list functionality.
- Route: `get "/orders", Hospital.OrdersController, :show`
- Replace the `:show` action with modern orders table
- Keep "Bulk Order" and "Admission Order" buttons on the page

---

#### 2. Admin Default View
**Question:** When an admin user lands on the orders page without selecting networks, what should they see?

**✅ DECISION:** Show all orders based on user's access level by default.
- Admin: See ALL orders from all networks
- Facility User: See all facility orders
- Campus User: See all campus orders
- Sort: Latest orders first (order_date DESC)
- Pagination: Required (10, 25, 50, 100 items per page)

---

#### 3. Table Features Priority
**Question:** Which features should be included in the orders table? (Select all that apply)

- [x] **Search** (by patient name, bag ID, MRN)
- [x] **Status filter** (Draft, Pending, Approved, Rejected)
- [x] **Date range filter** (Order date)
- [x] **Sorting** (by date, patient name, status)
- [x] **Pagination** (items per page: 10, 25, 50, 100)
- [ ] **Export** (CSV, PDF)
- [ ] **Bulk actions** (approve multiple, delete multiple)

**Recommendation:** All except Export and Bulk actions for MVP



---

#### 4. Patient Selection UI
**Question:** How should the admitted patients list be displayed?

**✅ DECISION:** Modal overlay for patient selection.
- When "Admission Order" button clicked → Open modal
- Modal shows admitted patients list with:
  - Patient Name
  - MRN (Medical Record Number)
  - Admission Date
  - Age
  - Ward
  - Patient Type
  - Campus/Facility info
  - "Create Order" button per patient
- On patient selection → Navigate to `/patients/:patient_id/orders/new` (existing form)
- Modal closes automatically on navigation

---

#### 5. Order Status Visibility
**Question:** Should users see orders in all statuses or filtered by default?

**Options:**
- [x] **Option A:** Show all statuses by default
- [ ] **Option B:** Show only "Pending" and "Approved" by default
- [ ] **Option C:** Show only user's own orders by default
- [ ] **Option D:** Configurable per user role

**Recommendation:** Option A with easy status filtering

---

#### 6. Network Selection Behavior
**Question:** For LHN users, should they see a network dropdown?

**✅ DECISION:** Network dropdowns are ONLY for creating Bulk Orders.
- Network selection fields (LHN → Facility → Campus) appear when creating bulk orders
- NOT used for filtering the orders table
- Orders table always shows orders based on user's inherent network access
- Admin creating bulk order: Shows LHN → Facility → Campus dropdowns
- Facility user creating bulk order: Shows Campus dropdown
- Campus user creating bulk order: No dropdowns (uses their campus)

---

#### 7. Order Actions
**Question:** What actions should be available on each order in the table?

**✅ DECISION:** Available actions per order:
- **View** - View order details (read-only) - All orders
- **Edit** - Edit order - Only for draft status orders
- **Copy** - Duplicate order - Only for approved status orders
  - Can copy both Patient Specific and Batch Production orders
  - For Patient Specific: Can copy to same patient or different patient
  - For Batch Production: Copy as new batch order
  - Copying opens patient selection modal (for patient orders) or bulk order form 

---

#### 8. Mobile Responsiveness
**Question:** How should the orders table behave on mobile devices?

**✅ DECISION:** Minimum tablet view support only.
- Use horizontal scroll for smaller screens
- No mobile-specific layout
- Minimum supported width: Tablet (768px+)
- Table remains fully functional with horizontal scrolling

---

### 🟡 OPTIONAL - Nice to Have

#### 9. Real-time Updates
**Question:** Should the orders list auto-refresh when new orders are created?

**✅ DECISION:** Manual refresh only with refresh button.
- Add refresh icon button in the page header
- Button triggers HTMX reload of the orders table
- No automatic polling or LiveView
- User controls when to refresh the data

---

#### 10. Order Notifications
**Question:** Should users receive notifications for order status changes?

- [ ] Yes, in-app notifications
- [ ] Yes, email notifications
- [x] No, not in this phase

---

## Database Changes

### Required Changes

#### None Expected
The existing schema should support all requirements:

- ✅ `orders` table has network relationships via `admission_id`
- ✅ `admissions` table has `campus_id`
- ✅ `campuses` table has `facility_id`
- ✅ `facilities` table has `local_health_network_id`
- ✅ `users` table has network fields

### Potential Optimizations

#### Indexes to Consider
```sql
-- For faster order queries by network
CREATE INDEX idx_orders_admission_id ON orders(admission_id);
CREATE INDEX idx_admissions_campus_id ON admissions(campus_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_order_date ON orders(order_date);

-- Composite index for common queries
CREATE INDEX idx_orders_status_date ON orders(status, order_date DESC);
```

**✅ DECISION:** Add indexes immediately during implementation.

---

## UI/UX Design

### Design System

- **Framework:** Phoenix + HTMX + Alpine.js
- **CSS:** TailwindCSS + BasecoatUI v0.3.6
- **Icons:** Heroicons (already in use)
- **Fonts:** Figtree (already configured)

### Color Scheme for Status Badges

```css
/* Based on existing patterns */
.status-draft { @apply bg-gray-100 text-gray-800; }
.status-pending { @apply bg-yellow-100 text-yellow-800; }
.status-approved { @apply bg-green-100 text-green-800; }
.status-rejected { @apply bg-red-100 text-red-800; }
```

### Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│ Breadcrumb: Home > Hospital > Orders                        │
├─────────────────────────────────────────────────────────────┤
│ Orders    [🔄] [Admission Order] [Bulk Order]               │
├─────────────────────────────────────────────────────────────┤
│ Filters                                                     │
│ [Search...] [Status ▼] [Date Range] [Order Type ▼]         │
├─────────────────────────────────────────────────────────────┤
│ Orders Table                                                │
│ ┌──────┬──────┬──────────┬──────┬────────┬────────┬──────┐ │
│ │ Type │ Bag  │ Patient  │ Date │ Status │ Campus │ Act. │ │
│ ├──────┼──────┼──────────┼──────┼────────┼────────┼──────┤ │
│ │ 🏥   │ ...  │ ...      │ ...  │ ...    │ ...    │ [⋮]  │ │
│ └──────┴──────┴──────────┴──────┴────────┴────────┴──────┘ │
├─────────────────────────────────────────────────────────────┤
│ Pagination: [<] 1 2 3 ... 10 [>]  [10 ▼] items per page    │
└─────────────────────────────────────────────────────────────┘

Patient Selection Modal (when "Admission Order" clicked):
┌─────────────────────────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Select Patient                                      [X] │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ [Search patients...]                                    │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ ┌────────────────────────────────────────────────────┐  │ │
│ │ │ John Doe | MRN: 12345 | Age: 45 | Ward: ICU       │  │ │
│ │ │ Admitted: 2026-04-01 | Type: Adult | Campus: Main │  │ │
│ │ │                              [Create Order] ────────→ │ │
│ │ └────────────────────────────────────────────────────┘  │ │
│ │ ┌────────────────────────────────────────────────────┐  │ │
│ │ │ Jane Smith | MRN: 67890 | Age: 32 | Ward: Med     │  │ │
│ │ │ Admitted: 2026-04-02 | Type: Adult | Campus: Main │  │ │
│ │ │                              [Create Order] ────────→ │ │
│ │ └────────────────────────────────────────────────────┘  │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Timeline

| Phase | Tasks | Estimated Time | Dependencies |
|-------|-------|----------------|--------------|
| **Phase 1** | Backend Data Layer | 2-3 hours | None |
| **Phase 2** | Controller & Routes | 3-4 hours | Phase 1 |
| **Phase 3** | Orders List UI | 4-5 hours | Phase 2 |
| **Phase 4** | Patient Selection UI | 3-4 hours | Phase 2 |
| **Phase 5** | Integration & Testing | 2-3 hours | Phase 3, 4 |

**Total Estimated Time:** 14-19 hours

---

## Next Steps

1. **Review this plan** and answer the questions above
2. **Approve or modify** the implementation approach
3. **Prioritize features** for MVP vs future enhancements
4. **Begin implementation** starting with Phase 1

---

## Notes & Assumptions

- Existing order form at `/patients/:patient_id/orders/new` will remain unchanged
- Network hierarchy is already implemented and working
- BasecoatUI components are available and documented
- HTMX is already integrated in the project
- User authentication and authorization are working

---

**Document Status:** ✅ APPROVED - Ready for Implementation

**Last Updated:** April 5, 2026 - 1:21 PM

---

## Summary of Final Decisions

### Key Features
1. **Replace** existing `/orders` page with modern orders table
2. **Patient Selection Modal** for admission orders (not separate page)
3. **Network dropdowns** only for bulk order creation (not for filtering)
4. **Order Type badges** to distinguish Patient vs Bulk orders
5. **Copy functionality** only for approved orders
6. **Tablet minimum** responsive design (horizontal scroll)
7. **Manual refresh** with refresh button (no auto-polling)
8. **Database indexes** created immediately

### User Experience Flow
- Landing page shows all orders based on user's network access
- "Admission Order" button → Opens modal → Select patient → Navigate to order form
- "Bulk Order" button → Opens bulk order form with network selection
- Copy approved orders → For patient orders: opens patient modal; For bulk: opens form
- Edit only draft orders
- View all orders (read-only)

### Technical Stack
- Phoenix + HTMX + Alpine.js
- BasecoatUI v0.3.6 components
- TailwindCSS styling
- Existing network access infrastructure
