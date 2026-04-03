/**
 * TPN Calculations Module
 *
 * This module provides comprehensive calculation functions for TPN orders.
 * It handles infusion calculations, nutritional calculations, electrolyte summaries,
 * nutritional summaries, and osmolarity validation.
 */

const TpnCalculations = (function () {
  "use strict";

  // Constants
  const CALORIC_VALUES = {
    PROTEIN: 4.0, // kcal/g
    DEXTROSE: 3.4, // kcal/g
    LIPID: 9.0, // kcal/g
    NITROGEN_FACTOR: 0.16, // 16% nitrogen in protein
  };

  const ELECTROLYTE_NAMES = [
    "sodium",
    "potassium",
    "calcium",
    "magnesium",
    "phosphate",
    "chloride",
    "acetate",
  ];

  /**
   * Calculate total osmoles from products data
   * @param {Array} productsData - Array of product objects
   * @returns {number} Total osmoles
   */
  function calculateTotalOsmoles(productsData) {
    return productsData.reduce((total, product) => {
      const osmolarity = parseFloat(product.osmolarity) || 0;
      const volume = parseFloat(product.volume) || 0;
      return total + osmolarity * volume;
    }, 0);
  }

  /**
   * Calculate osmolarity (mOsm/L) from total osmoles and total volume
   * @param {number} totalOsmoles - Total osmoles
   * @param {number} totalVolumeMl - Total volume in milliliters
   * @returns {number} Osmolarity in mOsm/L
   */
  function calculateOsmolarity(totalOsmoles, totalVolumeMl) {
    if (totalVolumeMl === 0) return 0;
    return (totalOsmoles / totalVolumeMl) * 1000;
  }

  /**
   * Calculate infusion rates for TPN order
   * @param {Object} orderAttrs - Order attributes
   * @param {Object} template - Template object
   * @param {Array} productsData - Array of product objects
   * @returns {Object} Infusion calculations
   */
  function calculateInfusionRates(orderAttrs, template, productsData) {
    const bagVolume = parseFloat(template.fluids) || 0;
    const overfillVolume = parseFloat(template.bag_over_fill_volume) || 0;
    const totalVolume = bagVolume + overfillVolume;

    const tpnDuration = parseInt(orderAttrs.tpn_infusion_duration_hours) || 24;
    const tpnInfusionType = orderAttrs.tpn_infusion_type;

    // For 3-in-1 bags, lipids are infused as part of TPN (no separate lipid infusion)
    let lipidDuration =
      parseInt(orderAttrs.lipid_infusion_duration_hours) || 24;
    let lipidVolume = 0;
    let lipidRate = 0;

    // Only calculate separate lipid infusion for 2-in-1 bags
    if (tpnInfusionType !== "3_in_1") {
      const lipidProduct = findProductByClass(productsData, [
        "lipid",
        "fat",
        "lipids",
      ]);
      if (lipidProduct && lipidProduct.formulary_id) {
        // Use volume directly from product data (already calculated)
        lipidVolume = parseFloat(lipidProduct.volume) || 0;
        lipidRate = lipidDuration > 0 ? lipidVolume / lipidDuration : 0;
      }
    } else {
      // For 3-in-1 bags, lipid duration equals TPN duration and lipids are part of TPN
      lipidDuration = tpnDuration;
      lipidRate = 0; // Lipids infused as part of TPN, no separate rate
    }

    // Calculate TPN rate based on bag volume
    const tpnRate = tpnDuration > 0 ? totalVolume / tpnDuration : 0;

    // Get enteral dose from order attributes
    const enteralDose = parseFloat(orderAttrs.enteral_dose) || 0;

    // Total fluids = (TPN Rate * Duration) + (Lipid rate * duration) + Enteral Product Dose
    const totalFluids =
      tpnRate * tpnDuration + lipidRate * lipidDuration + enteralDose;

    return {
      tpnRate: parseFloat(tpnRate.toFixed(2)),
      lipidRate: parseFloat(lipidRate.toFixed(2)),
      totalFluids: parseFloat(totalFluids.toFixed(2)),
      customTpnRate: 0, // To be implemented if needed for premixed standard templates
    };
  }

  /**
   * Parse dosing weight string to number
   * @param {string} dosingWeightStr - Dosing weight string
   * @returns {number} Parsed weight
   */
  function parseDosingWeight(dosingWeightStr) {
    const weight = parseFloat(dosingWeightStr);
    return isNaN(weight) ? 0 : weight;
  }

  /**
   * Find product by class keywords
   * @param {Array} productsData - Array of product objects
   * @param {Array} classKeywords - Array of keywords to search in class_name
   * @returns {Object|null} Found product or null
   */
  function findProductByClass(productsData, classKeywords) {
    return productsData.find((product) => {
      const className = (product.class_name || "").toLowerCase();
      return classKeywords.some((keyword) => className.includes(keyword));
    });
  }

  /**
   * Calculate total volume from products data
   * @param {Array} productsData - Array of product objects
   * @returns {number} Total volume in ml
   */
  function calculateTotalVolume(productsData) {
    return productsData.reduce((total, product) => {
      return total + (parseFloat(product.volume) || 0);
    }, 0);
  }

  /**
   * Calculate nutritional values for TPN order
   * @param {Object} orderAttrs - Order attributes
   * @param {Array} productsData - Array of product objects
   * @param {Object} template - Template object
   * @returns {Object} Nutritional calculations
   */
  function calculateNutritionalValues(orderAttrs, productsData, template) {
    const dosingWeight = parseDosingWeight(orderAttrs.dosing_weight || "0");
    const tpnDuration = parseInt(orderAttrs.tpn_infusion_duration_hours) || 24;
    let lipidDuration =
      parseInt(orderAttrs.lipid_infusion_duration_hours) || 24;
    // For 3-in-1 bags, lipid duration equals TPN duration
    const tpnInfusionType = orderAttrs.tpn_infusion_type;
    if (tpnInfusionType === "3_in_1") {
      lipidDuration = tpnDuration;
    }

    // Find key products
    const aminoAcidProduct = findProductByClass(productsData, [
      "amino",
      "acid",
      "protein",
    ]);
    const dextroseProduct = findProductByClass(productsData, [
      "dextrose",
      "glucose",
      "carbohydrate",
    ]);
    const lipidProduct = findProductByClass(productsData, [
      "lipid",
      "fat",
      "lipids",
    ]);

    // Get bag volume from template (in mL)
    const bagVolume = parseFloat(template.fluids) || 0;

    // Calculate GIR (Glucose Infusion Rate) in mg/kg/min
    let gir = 0;
    if (dextroseProduct && dosingWeight > 0 && tpnDuration > 0) {
      const dextroseDoseG = parseFloat(dextroseProduct.dose) || 0;
      const dextroseDoseMg = dextroseDoseG * 1000; // Convert g to mg
      gir = dextroseDoseMg / dosingWeight / (tpnDuration * 60);
    }

    // Calculate percentages based on bag volume
    let aminoAcidPercent = 0;
    let dextrosePercent = 0;

    if (aminoAcidProduct && bagVolume > 0) {
      const aminoAcidDoseG = parseFloat(aminoAcidProduct.dose) || 0;
      aminoAcidPercent = (aminoAcidDoseG / bagVolume) * 100;
    }

    if (dextroseProduct && bagVolume > 0) {
      const dextroseDoseG = parseFloat(dextroseProduct.dose) || 0;
      dextrosePercent = (dextroseDoseG / bagVolume) * 100;
    }

    // Calculate fat infusion rate in g/kg/hour
    let fatInfusionRate = 0;
    if (lipidProduct && dosingWeight > 0 && lipidDuration > 0) {
      const lipidDoseG = parseFloat(lipidProduct.dose) || 0;
      fatInfusionRate = lipidDoseG / dosingWeight / lipidDuration;
    }

    // Calculate osmolarity in mOsm/L
    // Use total volume from products (sum of product volumes) instead of bag volume
    // This matches the backend calculation logic
    const totalOsmoles = calculateTotalOsmoles(productsData);
    const totalVolume = calculateTotalVolume(productsData);
    const osmolarity = totalVolume > 0 ? (totalOsmoles / totalVolume) * 1000 : 0;

    return {
      gir: parseFloat(gir.toFixed(2)),
      aminoAcidPercent: parseFloat(aminoAcidPercent.toFixed(2)),
      dextrosePercent: parseFloat(dextrosePercent.toFixed(2)),
      fatInfusionRate: parseFloat(fatInfusionRate.toFixed(2)),
      osmolarity: parseFloat(osmolarity.toFixed(2)),
    };
  }

  /**
   * Calculate electrolyte totals from products data
   * @param {Array} productsData - Array of product objects
   * @returns {Object} Electrolyte summary
   */
  function calculateElectrolyteTotals(productsData) {
    const totals = {
      sodium: 0,
      potassium: 0,
      calcium: 0,
      magnesium: 0,
      phosphate: 0,
      chloride: 0,
      acetate: 0,
    };

    productsData.forEach((product) => {
      const electrolyteContributions = product.electrolyte_contributions || {};

      ELECTROLYTE_NAMES.forEach((electrolyte) => {
        const amount = parseFloat(electrolyteContributions[electrolyte]) || 0;
        totals[electrolyte] += amount;
      });
    });

    // Round to 2 decimal places
    Object.keys(totals).forEach((key) => {
      totals[key] = parseFloat(totals[key].toFixed(2));
    });

    return totals;
  }

  /**
   * Calculate nutritional summary from products data
   * @param {Array} productsData - Array of product objects
   * @returns {Object} Nutritional summary
   */
  function calculateNutritionalSummary(productsData) {
    // Find key products
    const aminoAcidProduct = findProductByClass(productsData, [
      "amino",
      "acid",
      "protein",
    ]);
    const dextroseProduct = findProductByClass(productsData, [
      "dextrose",
      "glucose",
      "carbohydrate",
    ]);
    const lipidProduct = findProductByClass(productsData, [
      "lipid",
      "fat",
      "lipids",
    ]);

    // Calculate energy values (kcal)
    let proteinEnergy = 0;
    let dextroseEnergy = 0;
    let lipidEnergy = 0;

    if (aminoAcidProduct) {
      const proteinDoseG = parseFloat(aminoAcidProduct.dose) || 0;
      proteinEnergy = proteinDoseG * CALORIC_VALUES.PROTEIN;
    }

    if (dextroseProduct) {
      const dextroseDoseG = parseFloat(dextroseProduct.dose) || 0;
      dextroseEnergy = dextroseDoseG * CALORIC_VALUES.DEXTROSE;
    }

    if (lipidProduct) {
      const lipidDoseG = parseFloat(lipidProduct.dose) || 0;
      lipidEnergy = lipidDoseG * CALORIC_VALUES.LIPID;
    }

    // Calculate nitrogen (g)
    let nitrogen = 0;
    if (aminoAcidProduct) {
      const proteinDoseG = parseFloat(aminoAcidProduct.dose) || 0;
      nitrogen = proteinDoseG * CALORIC_VALUES.NITROGEN_FACTOR;
    }

    // Calculate derived values
    const nonProteinEnergy = dextroseEnergy + lipidEnergy;
    const totalEnergy = proteinEnergy + nonProteinEnergy;

    // Calculate ratios
    const totalKcalPerNitrogen = nitrogen > 0 ? totalEnergy / nitrogen : 0;
    const proteinEnergyPerNitrogen =
      nitrogen > 0 ? proteinEnergy / nitrogen : 0;
    const nonProteinEnergyPerNitrogen =
      nitrogen > 0 ? nonProteinEnergy / nitrogen : 0;
    const proteinToNonProteinRatio =
      nonProteinEnergy > 0 ? proteinEnergy / nonProteinEnergy : 0;
    const lipidToTotalEnergyRatio =
      totalEnergy > 0 ? lipidEnergy / totalEnergy : 0;

    return {
      proteinEnergy: parseFloat(proteinEnergy.toFixed(2)),
      dextroseEnergy: parseFloat(dextroseEnergy.toFixed(2)),
      lipidEnergy: parseFloat(lipidEnergy.toFixed(2)),
      nitrogen: parseFloat(nitrogen.toFixed(2)),
      nonProteinEnergy: parseFloat(nonProteinEnergy.toFixed(2)),
      totalEnergy: parseFloat(totalEnergy.toFixed(2)),
      totalKcalPerNitrogen: parseFloat(totalKcalPerNitrogen.toFixed(2)),
      proteinEnergyPerNitrogen: parseFloat(proteinEnergyPerNitrogen.toFixed(2)),
      nonProteinEnergyPerNitrogen: parseFloat(
        nonProteinEnergyPerNitrogen.toFixed(2),
      ),
      proteinToNonProteinRatio: parseFloat(proteinToNonProteinRatio.toFixed(2)),
      lipidToTotalEnergyRatio: parseFloat(lipidToTotalEnergyRatio.toFixed(2)),
    };
  }

  /**
   * Validate osmolarity against limits
   * @param {number} calculatedOsmolarity - Calculated osmolarity value
   * @param {Object} osmolarityLimitRecord - Osmolarity limit record from database
   * @returns {Object} Validation results
   */
  function validateOsmolarity(calculatedOsmolarity, osmolarityLimitRecord) {
    if (!osmolarityLimitRecord) {
      return {
        exceeds: false,
        limit: 0,
        calculated: calculatedOsmolarity,
        exceeds_limit: 0,
        alert_type: null,
        patient_type_id: null,
        vascular_access_id: null,
        checked_at: new Date().toISOString(),
      };
    }

    const limit = parseFloat(osmolarityLimitRecord.osmolarity) || 0;
    const calculated = parseFloat(calculatedOsmolarity) || 0;
    const exceeds = calculated > limit;
    const exceedsLimit = exceeds ? calculated - limit : 0;

    return {
      exceeds: exceeds,
      limit: limit,
      calculated: calculated,
      exceeds_limit: parseFloat(exceedsLimit.toFixed(2)),
      alert_type: osmolarityLimitRecord.alert_type,
      patient_type_id: osmolarityLimitRecord.patient_type_id,
      vascular_access_id: osmolarityLimitRecord.vascular_access_id,
      checked_at: new Date().toISOString(),
    };
  }

  /**
   * Determine if an order can proceed based on osmolarity validation
   * @param {Object} alertResult - Result from validateOsmolarity
   * @param {boolean} hasComments - Whether user has provided comments for override
   * @returns {Object} Proceed decision with message
   */
  function canProceedWithOrder(alertResult, hasComments = false) {
    const { exceeds, alert_type } = alertResult;

    if (!exceeds) {
      return {
        canProceed: true,
        type: "info",
        message: "Osmolarity is within safe limits.",
      };
    }

    switch (alert_type) {
      case "Soft":
        if (hasComments) {
          return {
            canProceed: true,
            type: "warning",
            message:
              "Osmolarity exceeds soft limit but order can proceed with comments.",
          };
        } else {
          return {
            canProceed: false,
            type: "warning",
            message:
              "Osmolarity exceeds soft limit. Please provide comments to proceed.",
          };
        }

      case "Hard":
        return {
          canProceed: false,
          type: "error",
          message: "Osmolarity exceeds hard limit. Order cannot proceed.",
        };

      default:
        return {
          canProceed: false,
          type: "error",
          message: "Unknown alert type. Order cannot proceed.",
        };
    }
  }

  /**
   * Calculate all order values
   * @param {Object} orderAttrs - Order attributes
   * @param {Object} template - Template object
   * @param {Array} productsData - Array of product objects
   * @returns {Object} All calculated values
   */
  function calculateOrderValues(orderAttrs, template, productsData) {
    const infusionCalculations = calculateInfusionRates(
      orderAttrs,
      template,
      productsData,
    );
    const nutritionalCalculations = calculateNutritionalValues(
      orderAttrs,
      productsData,
      template,
    );
    const electrolyteSummary = calculateElectrolyteTotals(productsData);
    const nutritionalSummary = calculateNutritionalSummary(productsData);

    return {
      infusion_calculations: infusionCalculations,
      nutritional_calculations: nutritionalCalculations,
      electrolyte_summary: electrolyteSummary,
      nutritional_summary: nutritionalSummary,
      calculated_at: new Date().toISOString(),
    };
  }

  /**
   * Sort products by position for consistent ordering
   * @param {Array} products - Array of product objects
   * @returns {Array} Sorted products
   */
  function sortProductsByPosition(products) {
    return [...products].sort((a, b) => {
      const posA = parseInt(a.position) || 0;
      const posB = parseInt(b.position) || 0;
      return posA - posB;
    });
  }

  /**
   * Prepare products data for calculation
   * @param {Array} products - Raw products array
   * @returns {Array} Processed products data
   */
  function prepareProductsData(products) {
    return sortProductsByPosition(products).map((product, index) => ({
      id: product.id || index,
      position: parseInt(product.position) || index,
      class_id: product.class_id,
      class_name: product.class_name,
      dose: parseFloat(product.dose) || 0,
      dose_unit: product.dose_unit,
      formulary_id: product.formulary_id,
      formulary_name: product.formulary_name,
      filling_method_id: product.filling_method_id,
      filling_method_name: product.filling_method_name,
      volume: parseFloat(product.volume) || 0,
      fill_volume: parseFloat(product.fill_volume) || 0,
      additional_dose: parseFloat(product.additional_dose) || 0,
      additional_dose_unit: product.additional_dose_unit,
      max_allowed_limit: parseFloat(product.max_allowed_limit) || 0,
      max_allowed_unit: product.max_allowed_unit,
      substance_locked_on_order: Boolean(product.substance_locked_on_order),
      osmolarity: parseFloat(product.osmolarity) || 0,
      electrolyte_contributions: product.electrolyte_contributions || {},
    }));
  }

  // Public API
  return {
    calculateOrderValues,
    calculateInfusionRates,
    calculateNutritionalValues,
    calculateElectrolyteTotals,
    calculateNutritionalSummary,
    calculateTotalOsmoles,
    calculateOsmolarity,
    validateOsmolarity,
    canProceedWithOrder,
    prepareProductsData,
    sortProductsByPosition,
    findProductByClass,

    // Constants
    CALORIC_VALUES,
    ELECTROLYTE_NAMES,
  };
})();

// Export for use in browser
if (typeof window !== "undefined") {
  window.TpnCalculations = TpnCalculations;
}

// Export for Node.js/CommonJS
if (typeof module !== "undefined" && module.exports) {
  module.exports = TpnCalculations;
}
