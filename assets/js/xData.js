// Make orderForm available globally
window.orderForm = function() {
    return {
        showTpnInfusionDuration: false,        
    }
};

// Make orderTemplateProducts available globally
window.orderTemplateProducts = function() {
    return {
        preMixedStandard: false,
        additionalSubstancesAllowed: false,
        productsData: [],
        classes: [],
        handleSort: (item, position) => {
            console.log(item, position);
        },
        getClassFormularies: function (class_id) {
            const selectedClass = this.classes.find(cls => cls.id === class_id);
            if (!selectedClass) {
                return [];
            }

            return selectedClass.formularies;
        }
    }
};

// Register with Alpine.js when it's ready
document.addEventListener('alpine:init', () => {
    Alpine.data('orderForm', window.orderForm);
    Alpine.data('orderTemplateProducts', window.orderTemplateProducts);
});