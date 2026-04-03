// Make orderForm available globally
window.orderForm = function () {
  return {
    showTpnInfusionDuration: false,
  };
};

// Make orderTemplateProducts available globally
window.orderTemplateProducts = function () {
  return {
    preMixedStandard: false,
    additionalSubstancesAllowed: false,
    query: "",
    productsData: [],
    classes: [],
    substances: [],
    fillingMethods: [],
    formularies: [],
    selectedFormulary: null,
    currency: null,
    productsToAdd: [],
    substanceToAdd: {
      class_id: null,
      products: [],
      volume: null,
      fill_volume: null,
    },

    // Calculation properties
    calculations: {
      infusion: {
        tpnRate: 0,
        lipidRate: 0,
        totalFluids: 0,
        customTpnRate: 0,
      },
      nutritional: {
        gir: 0,
        aminoAcidPercent: 0,
        dextrosePercent: 0,
        fatInfusionRate: 0,
        osmolarity: 0,
      },
    },
    osmolarityAlert: null,
    osmolarityLimit: null,
    osmolarityComments: "",
    showOsmolarityAlertModal: false,

    // Summary properties
    electrolyteTotals: {
      sodium: 0,
      potassium: 0,
      calcium: 0,
      magnesium: 0,
      phosphate: 0,
      chloride: 0,
      acetate: 0,
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
      lipidToTotalEnergyRatio: 0,
    },

    initialized: function () {
      this.productsData.forEach((product, index) => {
        product.volume = 0.0;
        product.fill_volume = 0.0;
        product.position = index;
        product.substance_id = index;
      });
      console.log(this.productsData);
      this.watchOrderAttributes();
      this.setupOsmolarityOverrideListener();
    },

    setupOsmolarityOverrideListener: function () {
      // Listen for osmolarity override confirmation from modal
      window.addEventListener('osmolarity-override-confirmed', (event) => {
        if (event.detail) {
          this.osmolarityComments = event.detail.comments;
          this.osmolarityAlert = event.detail.alert;

          // Update the hidden field with osmolarity alert data
          this.updateOsmolarityAlertField();

          // Dismiss the alert banner
          window.dispatchEvent(new CustomEvent('osmolarity-alert-dismissed'));

          console.log('Osmolarity override confirmed:', {
            comments: this.osmolarityComments,
            alert: this.osmolarityAlert
          });
        }
      });
    },

    updateOsmolarityAlertField: function () {
      // Prepare osmolarity alert data for backend
      const osmolarityData = {
        alert: this.osmolarityAlert,
        comments: this.osmolarityComments,
        overridden_at: new Date().toISOString(),
        user_id: document.getElementById("user_id")?.value,
      };

      // Set hidden field for backend processing
      const hiddenField = document.getElementById("osmolarity_alert_data");
      if (hiddenField) {
        hiddenField.value = JSON.stringify(osmolarityData);
      }
    },
    watchOrderAttributes: function () {
      // Watch for changes to order form inputs
      const orderInputIds = [
        "tpn_infusion_duration_hours",
        "lipid_infusion_duration_hours",
        "dosing_weight",
      ];

      orderInputIds.forEach((id) => {
        const input = document.getElementById(id);
        if (input) {
          input.addEventListener("input", () => {
            this.calculateAllValues();
          });
          input.addEventListener("change", () => {
            this.calculateAllValues();
          });
        }
      });
    },
    addProduct: function () {
      document.getElementById("add_substances").showModal();
    },

    handleSort: (item, position) => {
      console.log(item, position);
    },

    // Calculation methods
    calculateAllValues: function () {
      console.log("calculateAllValues called", {
        productsCount: this.productsData?.length || 0,
        hasTpnCalculations: !!window.TpnCalculations,
      });

      if (!window.TpnCalculations) {
        console.error("TpnCalculations module not loaded");
        return;
      }

      // Get order attributes from the form
      const orderAttrs = this.getOrderAttributes();
      const template = this.getTemplateData();

      // Recalculate product volumes before preparing data for calculations
      this.recalculateProductVolumes();

      const productsData = TpnCalculations.prepareProductsData(
        this.productsData,
      );

      // Calculate all values
      const calculatedValues = TpnCalculations.calculateOrderValues(
        orderAttrs,
        template,
        productsData,
      );

      // Update component state
      this.calculations.infusion = calculatedValues.infusion_calculations;
      this.calculations.nutritional = calculatedValues.nutritional_calculations;
      this.electrolyteTotals = calculatedValues.electrolyte_summary;
      this.nutritionalSummary = calculatedValues.nutritional_summary;

      // Emit calculation events for summary cards
      this.emitCalculationEvents(calculatedValues);

      // Check osmolarity if patient type and vascular access are available
      this.checkOsmolarity();

      console.log("calculateAllValues completed", {
        infusion: this.calculations.infusion,
        nutritional: this.calculations.nutritional,
        electrolyteTotals: this.electrolyteTotals,
        nutritionalSummary: this.nutritionalSummary,
      });

      return calculatedValues;
    },

    // Emit calculation events for other components
    emitCalculationEvents: function (calculatedValues) {
      // Emit event for summary cards
      window.dispatchEvent(
        new CustomEvent("order-calculations-updated", {
          detail: {
            infusion: calculatedValues.infusion_calculations,
            nutritional: calculatedValues.nutritional_calculations,
            electrolyteTotals: calculatedValues.electrolyte_summary,
            nutritionalSummary: calculatedValues.nutritional_summary,
          },
        }),
      );

      // Emit osmolarity alert if needed
      if (calculatedValues.nutritional_calculations?.osmolarity) {
        const osmolarity = calculatedValues.nutritional_calculations.osmolarity;
        window.dispatchEvent(
          new CustomEvent("osmolarity-calculated", {
            detail: { osmolarity },
          }),
        );
      }
    },

    getOrderAttributes: function () {
      // Get all order form data from DOM
      return {
        vascular_access_id:
          document.getElementById("vascular_access_id")?.value || null,
        formulary_id: document.getElementById("formulary_id")?.value || null,
        enteral_dose: document.getElementById("enteral_dose")?.value || "0",
        infusion_duration_type:
          document.getElementById("infusion_duration_type")?.value || null,
        lipid_infusion_duration_hours:
          document.getElementById("lipid_infusion_duration_hours")?.value || 24,
        tpn_infusion_type:
          document.getElementById("tpn_infusion_type")?.value || null,
        tpn_infusion_duration_hours:
          document.getElementById("tpn_infusion_duration_hours")?.value || 24,
        dosing_weight: document.getElementById("dosing_weight")?.value || "0",
        patient_type_id:
          document.getElementById("patient_type_id")?.value || null,
        template_fluids: {}, // Will be populated from template
      };
    },

    getTemplateData: function () {
      // This should be connected to the actual template data
      // For now, return mock data or get from DOM
      return {
        fluids: document.getElementById("template_fluids")?.value || 1000,
        bag_over_fill_volume:
          document.getElementById("bag_over_fill_volume")?.value || 100,
      };
    },

    checkOsmolarity: function () {
      if (!window.TpnCalculations) return;

      const patientTypeId = document.getElementById("patient_type_id")?.value;
      const vascularAccessId =
        document.getElementById("vascular_access_id")?.value;

      if (!patientTypeId || !vascularAccessId) {
        console.log("Patient type or vascular access not selected");
        return;
      }

      // Fetch osmolarity limit from API
      this.fetchOsmolarityLimit(patientTypeId, vascularAccessId);
    },

    fetchOsmolarityLimit: function (patientTypeId, vascularAccessId) {
      const url = `/api/osmolarity/limit?patient_type_id=${patientTypeId}&vascular_access_id=${vascularAccessId}`;

      fetch(url)
        .then((response) => response.json())
        .then((data) => {
          if (data.success) {
            this.osmolarityLimit = data.data;

            // Emit event for summary cards to receive the limit
            window.dispatchEvent(
              new CustomEvent("osmolarity-limit-fetched", {
                detail: data.data,
              })
            );

            this.validateCurrentOsmolarity();
          } else {
            console.warn("No osmolarity limit found:", data.message);
            this.osmolarityLimit = null;

            // Emit null limit event
            window.dispatchEvent(
              new CustomEvent("osmolarity-limit-fetched", {
                detail: null,
              })
            );
          }
        })
        .catch((error) => {
          console.error("Error fetching osmolarity limit:", error);
          this.osmolarityLimit = null;
        });
    },

    validateCurrentOsmolarity: function () {
      if (!this.osmolarityLimit || !window.TpnCalculations) return;

      const calculatedOsmolarity = this.calculations.nutritional.osmolarity;
      const validationResult = TpnCalculations.validateOsmolarity(
        calculatedOsmolarity,
        this.osmolarityLimit,
      );

      this.osmolarityAlert = validationResult;

      // Emit validation result event for alert components
      window.dispatchEvent(
        new CustomEvent("osmolarity-validation-result", {
          detail: {
            alert: validationResult,
            limit: this.osmolarityLimit,
          },
        })
      );

      // Check if we need to show alert modal
      if (validationResult.exceeds) {
        const canProceed = TpnCalculations.canProceedWithOrder(
          validationResult,
          this.osmolarityComments.trim().length > 0,
        );

        if (!canProceed.canProceed) {
          this.showOsmolarityAlertModal = true;

          // Show override modal for soft limits
          if (validationResult.alert_type === "Soft") {
            window.dispatchEvent(
              new CustomEvent("show-osmolarity-override-modal", {
                detail: validationResult,
              })
            );
          }
        }
      }
    },

    handleOsmolarityOverride: function () {
      if (!this.osmolarityAlert) return;

      const canProceed = TpnCalculations.canProceedWithOrder(
        this.osmolarityAlert,
        this.osmolarityComments.trim().length > 0,
      );

      if (canProceed.canProceed) {
        this.showOsmolarityAlertModal = false;
        // Proceed with order submission
        this.submitOrderWithOsmolarityOverride();
      } else {
        // Show error message
        alert(canProceed.message);
      }
    },

    submitOrderWithOsmolarityOverride: function () {
      // This will be called when order is submitted with osmolarity override
      console.log("Submitting order with osmolarity override:", {
        alert: this.osmolarityAlert,
        comments: this.osmolarityComments,
      });

      // Add osmolarity alert data to form submission
      const osmolarityData = {
        alert: this.osmolarityAlert,
        comments: this.osmolarityComments,
        overridden_at: new Date().toISOString(),
        user_id: document.getElementById("user_id")?.value,
      };

      // Set hidden field for backend processing
      const hiddenField = document.getElementById("osmolarity_alert_data");
      if (hiddenField) {
        hiddenField.value = JSON.stringify(osmolarityData);
      }
    },

    updateProductCalculations: function (productId) {
      const product = this.productsData.find((p) => p.id === productId);
      if (!product) return;

      // Update product-specific calculations
      if (product.formulary_id) {
        const formulary = this.formularies.find(
          (f) => f.id === product.formulary_id,
        );
        if (formulary) {
          // Update osmolarity and electrolyte contributions from formulary
          product.osmolarity = formulary.osmolarity || 0;
          product.electrolyte_contributions =
            formulary.electrolyte_contributions || {};
        }
      }

      // Recalculate all values
      const calculatedValues = this.calculateAllValues();

      // Emit product update event
      window.dispatchEvent(
        new CustomEvent("product-calculations-updated", {
          detail: {
            productId,
            product,
            calculatedValues,
          },
        }),
      );
    },

    // Drag and drop sorting
    draggedProduct: null,

    dragStart: function (productId) {
      this.draggedProduct = productId;
    },

    dragOver: function (event) {
      event.preventDefault();
    },

    drop: function (targetProductId) {
      if (!this.draggedProduct || this.draggedProduct === targetProductId)
        return;

      const draggedIndex = this.productsData.findIndex(
        (p) => p.id === this.draggedProduct,
      );
      const targetIndex = this.productsData.findIndex(
        (p) => p.id === targetProductId,
      );

      if (draggedIndex === -1 || targetIndex === -1) return;

      // Remove dragged product
      const [draggedItem] = this.productsData.splice(draggedIndex, 1);

      // Insert at target position
      this.productsData.splice(targetIndex, 0, draggedItem);

      // Update positions
      this.productsData.forEach((product, index) => {
        product.position = index;
      });

      // Recalculate
      this.calculateAllValues();

      this.draggedProduct = null;
    },

    // Volume calculations
    calculateBagVolume: function () {
      const bagVolume =
        parseFloat(document.getElementById("template_fluids")?.value) || 0;
      const overfillVolume =
        parseFloat(document.getElementById("bag_over_fill_volume")?.value) || 0;
      return {
        bagVolume: bagVolume,
        overfillVolume: overfillVolume,
        totalVolume: bagVolume + overfillVolume,
      };
    },

    calculateProductVolume: function (product) {
      if (!product.formulary_id) return 0;

      const formulary = this.formularies.find(
        (f) => f.id === product.formulary_id,
      );
      if (!formulary || !formulary.concentration) return 0;

      const dose = parseFloat(product.dose) || 0;
      const concentration = parseFloat(formulary.concentration) || 1;

      return dose / concentration;
    },

    recalculateProductVolumes: function () {
      // Recalculate volume and fill volume for all products
      this.productsData.forEach((product) => {
        const volume = this.calculateProductVolume(product);
        product.volume = parseFloat(volume.toFixed(4)) || 0;

        // Calculate fill volume based on bag volume and overfill
        const volumes = this.calculateBagVolume();
        const bagVolume = volumes.bagVolume;
        const overfillVolume = volumes.overfillVolume;
        const totalVolume = volumes.totalVolume;

        if (bagVolume > 0) {
          // Fill volume formula: (volume / bag volume) * (bag volume + overfill volume)
          product.fill_volume =
            parseFloat(((volume / bagVolume) * totalVolume).toFixed(4)) || 0;
        } else {
          product.fill_volume = 0;
        }
      });

      console.log("Recalculated product volumes", this.productsData);
    },

    // Event handlers for form changes
    onFormChange: function () {
      // Debounced recalculation
      clearTimeout(this.calculationTimeout);
      this.calculationTimeout = setTimeout(() => {
        const calculatedValues = this.calculateAllValues();

        // Emit form change event
        window.dispatchEvent(
          new CustomEvent("form-calculations-updated", {
            detail: {
              calculatedValues,
              timestamp: new Date().toISOString(),
            },
          }),
        );
      }, 300);
    },

    // Save calculations to form before submission
    saveCalculationsToForm: function () {
      const calculatedValues = this.calculateAllValues();

      // Set hidden fields for backend
      const fields = [
        "infusion_calculations",
        "nutritional_calculations",
        "electrolyte_summary",
        "nutritional_summary",
      ];

      fields.forEach((field) => {
        const hiddenField = document.getElementById(field);
        if (hiddenField) {
          hiddenField.value = JSON.stringify(calculatedValues[field]);
        }
      });

      // Set calculated_at
      const calculatedAtField = document.getElementById("calculated_at");
      if (calculatedAtField) {
        calculatedAtField.value = calculatedValues.calculated_at;
      }

      // Emit final calculation event before submission
      window.dispatchEvent(
        new CustomEvent("final-calculations-before-submit", {
          detail: calculatedValues,
        }),
      );

      return calculatedValues;
    },

    // Restore calculations from saved data
    restoreCalculations: function (data) {
      if (!data) return;

      if (data.infusion_calculations) {
        this.calculations.infusion = data.infusion_calculations;
      }

      if (data.nutritional_calculations) {
        this.calculations.nutritional = data.nutritional_calculations;
      }

      if (data.electrolyte_summary) {
        this.electrolyteTotals = data.electrolyte_summary;
      }

      if (data.nutritional_summary) {
        this.nutritionalSummary = data.nutritional_summary;
      }
    },
    getClassFormularies: function (class_id) {
      const formularies = this.formularies.filter(
        (cls) => cls.class_id === class_id,
      );
      if (!formularies.length) {
        return [];
      }

      return formularies;
    },
    openFormularyInfo: function (product_id) {
      const product = this.productsData.find(
        (product) => product.id === product_id,
      );
      if (!product || !product.formulary_id) {
        return;
      }

      const selected = this.formularies.find(
        (formulary) => formulary.id === product.formulary_id,
      );
      if (!selected) {
        return;
      }

      this.selectedFormulary = selected;

      document.getElementById("formulary_info").showModal();
    },
    handleProductChange: function (event, product_id) {
      const value = event.target.value;
      const product = this.productsData.find(
        (product) => product.id === product_id,
      );
      if (!value) {
        product.formulary_id = null;
        product.formulary_name = null;
        return;
      }

      const selected = this.formularies.find(
        (formulary) => formulary.id === parseInt(value),
      );
      if (!selected) {
        product.formulary_id = null;
        product.formulary_name = null;
        return;
      }

      product.formulary_id = selected.id;
      product.formulary_name = selected.name;

      // Update product calculations when formulary changes
      this.updateProductCalculations(product_id);

      // Emit formulary selection event
      window.dispatchEvent(
        new CustomEvent("formulary-selected", {
          detail: {
            productId: product_id,
            formularyId: selected.id,
            formularyName: selected.name,
          },
        }),
      );
    },
    onDoseChange: function (product_id) {
      const product = this.productsData.find((p) => p.id === product_id);
      if (!product) return;

      // Validate max allowed limit
      if (product.max_allowed_limit && product.max_allowed_limit > 0) {
        const dose = parseFloat(product.dose) || 0;
        const maxAllowed = parseFloat(product.max_allowed_limit) || 0;
        if (dose > maxAllowed) {
          alert(
            `Dose (${dose} ${product.dose_unit}) exceeds maximum allowed limit (${maxAllowed} ${product.max_allowed_unit}). Please adjust the dose.`,
          );
          // Optionally highlight the field or prevent further calculation
          return;
        }
      }

      // Recalculate volume for this product
      const volume = this.calculateProductVolume(product);
      product.volume = parseFloat(volume.toFixed(4)) || 0;

      // Recalculate fill volume
      const volumes = this.calculateBagVolume();
      const bagVolume = volumes.bagVolume;
      const totalVolume = volumes.totalVolume;

      if (bagVolume > 0) {
        product.fill_volume =
          parseFloat(((volume / bagVolume) * totalVolume).toFixed(4)) || 0;
      } else {
        product.fill_volume = 0;
      }

      // Trigger overall calculations
      this.calculateAllValues();
    },

    open_substances: function () {
      document.getElementById("add_substances").showModal();
    },
  };
};

// display formulariesIngredients
window.formulariesIngredients = function () {
  return {
    ingredients: [],
    all_ingredients: [],
    selected_ingredients: [],
    old_selected_ingredients: [],
    units: [],
    query: "",
    search_ingredients(query) {
      if (!query.trim()) {
        this.set_ingredients();
      } else {
        const notSelected = differenceBy(
          this.all_ingredients,
          this.selected_ingredients,
          "id",
        );
        this.ingredients = notSelected.filter((ingredient) =>
          ingredient.name.toLowerCase().includes(query.trim().toLowerCase()),
        );
      }
    },
    open_ingredients() {
      this.set_ingredients();
      this.query = "";
      document.getElementById("ingredients_modal").showModal();
    },
    set_ingredients() {
      this.ingredients = differenceBy(
        this.all_ingredients,
        this.selected_ingredients,
        "id",
      );
    },
    set_selected_ingredients() {
      this.selected_ingredients = this.old_selected_ingredients.map((i) => {
        const ingredient = this.all_ingredients.find(
          (a) => a.id === i.ingredient_id,
        );
        return {
          id: i.ingredient_id,
          name: ingredient.name,
          unit_id: i.unit_id,
          amount: i.amount,
        };
      });
      if (this.selected_ingredients.length) {
        this.set_ingredients();
      }
    },
    add_ingredient(ingredient) {
      this.selected_ingredients.push(ingredient);
      this.search_ingredients(this.query);
    },
    remove_ingredient(id) {
      this.selected_ingredients = this.selected_ingredients.filter(
        (i) => i.id !== id,
      );
      this.set_ingredients();
    },
    get_ingredient_name(id) {
      return this.all_ingredients.find((i) => i.id === id).name;
    },
  };
};

window.patientSearchFilter = function () {
  return {
    open_filter: false,
    filters: [
      "First Name",
      "Last Name",
      "TPN I.D",
      "I.D",
      "Location",
      "Email",
      "Phone",
    ],
    selected: "First Name",
    filter_patients: () => {
      document.body.dispatchEvent(new CustomEvent("reloadDataTable"));
    },
  };
};

// Register with Alpine.js when it's ready
document.addEventListener("alpine:init", () => {
  Alpine.data("orderForm", window.orderForm);
  Alpine.data("orderTemplateProducts", window.orderTemplateProducts);
  Alpine.data("formulariesIngredients", window.formulariesIngredients);
});
