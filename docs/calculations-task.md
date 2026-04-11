The task is to update and fix the orers form. If needed remove/update the files.


Requirements:
each product osmolarity will be used to calculate total bag osmolarity on the order form. Total bag osmolarity will be compared with values on the osmolarity on the osmolarity table and user will be alerted if bag osmolarity is higher than value on this table. For example, if patient type is adult, vascular access is peripheral and bag osmolarity is higher than 900 then user will be alerted and user won’t be able to process further.

**Osmolarities:**
- Osmoloarities:
    - table: osmolarities
        - alert_type: "Soft" or "Hard"
        - osmolirity
        - vascular_access_id
        - patient_type_id
    - osmolarities_view
        - view that joins osmolarities with vascular_accesses, patient_types and users tables

make decision which one to use

**Formularies**
- Formularies:
    - table: formularies
        - it also has osmolarity, which is displayed in order form under substances. They are not include there. also include them

**Order Form:**
when order form loaded template, it should also display the Total Osmolarity that can be administered based on patient type and vascular access. Order form already has calculations summary, it can display this value there.

- Order form should calculate total bag osmolarity based on products selected
- Order form should compare total bag osmolarity with values on the osmolarity table
- Order form should alert user if bag osmolarity is higher than value on this table
- Order form should not allow user to process further if bag osmolarity is higher than value on this table

**Form Structure:**
check images:
- order-new.png
- order-new-2.png

**Calculations:**
- Calculatio TPN.xlsx

Notes:
order under patient is not Batched orders, this has implemented with bugs and calculation. go and analyze it.
Orders under Left menu -> Orders can be Batched orders, which are not related to patient

1st create a plan under .aidocs directory and wait for approval before starting implementation