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
    productsData: [],
    classes: [],
    fillingMethods: [],
    formularies: [],
    selectedFormulary: null,
    currency: null,
    productsToAdd: [],
    initialized: function () {
      this.productsData.forEach((product) => {
        product.volume = 0.0;
        product.fill_volume = 0.0;
      });
      this.productsToAdd = this.classes.filter(
        (cls) => !this.productsData.some((p) => p.class_id !== cls.id),
      );
    },
    handleSort: (item, position) => {
      console.log(item, position);
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
    removeProduct: function (id) {
      this.productsData = this.productsData.filter(
        (product) => product.id !== id,
      );
    },
    addProduct: function (id) {
      this.productsData.push(
        this.productsToAdd.find((product) => product.id === id),
      );
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
