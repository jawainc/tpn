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
        fillingMethods: [],
        formularies: [],
        selectedFormulary: null,
        currency: null,
        productsToAdd: [],
        initialized: function () {
            this.productsData.forEach(product => {
                product.volume = 0.0;
                product.fill_volume = 0.0;
            });
            this.productsToAdd = this.classes.filter(cls => !this.productsData.some(p => p.class_id !== cls.id));
        },
        handleSort: (item, position) => {
            console.log(item, position);
        },
        getClassFormularies: function (class_id) {
            const formularies = this.formularies.filter(cls => cls.class_id === class_id);
            if (!formularies.length) {
                return [];
            }

            return formularies;
        },
        removeProduct: function (id) {
            this.productsData = this.productsData.filter(product => product.id !== id);
        },
        addProduct: function (id) {
            this.productsData.push(this.productsToAdd.find(product => product.id === id));
        },
        openFormularyInfo: function (product_id) {
            const product = this.productsData.find(product => product.id === product_id);
            if (!product || !product.formulary_id) {
                return;
            }

            const selected = this.formularies.find(formulary => formulary.id === product.formulary_id);
            if (!selected) {
                return;
            }

            this.selectedFormulary = selected;

            document.getElementById('formulary_info').showModal();
        },
        handleProductChange: function (event, product_id) {
            const value = event.target.value;
            const product = this.productsData.find(product => product.id === product_id);
            if (!value) {
                product.formulary_id = null;
                product.formulary_name = null;
                return;
            }

            const selected = this.formularies.find(formulary => formulary.id === parseInt(value));
            if (!selected) {
                product.formulary_id = null;
                product.formulary_name = null;
                return;
            }

            product.formulary_id = selected.id;
            product.formulary_name = selected.name;
        }
    }
};

// Register with Alpine.js when it's ready
document.addEventListener('alpine:init', () => {
    Alpine.data('orderForm', window.orderForm);
    Alpine.data('orderTemplateProducts', window.orderTemplateProducts);
});