/**
 * remove options from a select element
 * @param {*} id
 */
window.selectRemoveOptions = function (arg) {
  if (Array.isArray(arg)) {
    arg.forEach((id) => {
      const select = document.getElementById(id);
      if (select) {
        while (select.options.length > 1) {
          select.remove(1);
        }
      }
    });
    return;
  }

  const select = document.getElementById(arg);
  if (select) {
    while (select.options.length > 1) {
      select.remove(1);
    }
  }
};

/**
 * trigger events
 * @param {*} events
 */
window.triggerEvent = function (value, event, type, elm = "") {
  switch (event) {
    case "load_wards":
      load_wards(value, type, elm);
      break;
    case "load_rooms":
      load_rooms(value, elm);
      break;
    case "load_wards_with_mrn":
      load_wards(value, type, elm);
      load_mrn(value);
      break;
    case "load_beds":
      load_beds(value, elm);
      break;
    case "load_template_formularies":
      load_template_formularies();
      break;
    case "sort_products":
      sort_products(value);
      break;
    default:
      document.body.dispatchEvent(new CustomEvent(event, { detail: value }));
  }
};

window.filterPatients = function () {
  const filter = document.querySelector("input[name=filter]").value || "";
  const filter_by = document.querySelector("input[name=by_filter]").value || "";

  return {
    filter: filter,
    filter_by: filter_by,
  };
};

/**
 * adds/removes a class to an element based on the checked state of a checkbox
 * @param {*} element
 */
window.applyCheckboxSelector = function (element) {
  if (element.querySelector("input").checked) {
    element.classList.add("checkox-checked-indicator");
  } else {
    element.classList.remove("checkox-checked-indicator");
  }
};

window.load_wards = function (value, type, elm) {
  if (!value) {
    selectRemoveOptions([elm + "_ward_id", elm + "_room_id", elm + "_bed_id"]);
    return;
  }

  document.body.dispatchEvent(
    new CustomEvent("load_wards", { detail: { id: value, type: type } }),
  );
};

window.load_rooms = function (value, elm) {
  if (!value) {
    selectRemoveOptions([elm + "_room_id", elm + "_bed_id"]);
    return;
  }
  document.body.dispatchEvent(
    new CustomEvent("load_rooms", { detail: { id: value } }),
  );
};

window.load_beds = function (value, elm) {
  if (!value) {
    selectRemoveOptions(elm + "_bed_id");
    return;
  }
  document.body.dispatchEvent(
    new CustomEvent("load_beds", { detail: { id: value } }),
  );
};

window.load_template_formularies = function (value) {
  const template_id = document.getElementById(
    "template_product_template_id",
  ).value;

  const class_id = document.getElementById("template_product_class_id").value;

  document.body.dispatchEvent(
    new CustomEvent("load_template_formularies", {
      detail: {
        template_id: template_id,
        class_id: class_id,
      },
    }),
  );
};

window.load_mrn = function (value) {
  if (!value) {
    document.getElementById("mrn").value = "";
  }
  document.body.dispatchEvent(
    new CustomEvent("load_mrn", {
      detail: {
        campus_id: value,
        patient_id: document.getElementById("admission_patient_id").value,
      },
    }),
  );
};

window.sort_products = function (value) {
  const conatiner_div = document.getElementById("products_table");
  if (!conatiner_div) {
    return;
  }

  // get all children
  // convert to array
  const children = Array.from(conatiner_div.children);
  for (let i = 0; i < children.length; i++) {
    const child = children[i];
    const product_id = child.getAttribute("x-sort:item");
    const field = document.getElementById(`form_product_field_${product_id}`);
    field.value = `${product_id},${i}`;
  }

  document.body.dispatchEvent(new CustomEvent("updateProductsPositions"));
};

window.reinitializeSelect = function (select_id) {
  const select = document.getElementById(select_id);
  if (!select) {
    return;
  }

  // remove attribute, data-select-initialized="true"
  //select.removeAttribute("data-select-initialized");
};

window.swapElementStyle = function (id) {
  if (!id) {
    return "innerHTML";
  }

  const ids = ["select-container-template_product_formulary_id"];
  return ids.includes(id) ? "outerHTML" : "innerHTML";
};

window.handleIconLoader = function (id, spin = true, container = "") {
  const icon = document.getElementById(id);
  if (!icon) {
    return;
  }

  if (spin) {
    icon.classList.add("animate-spin");
  } else {
    icon.classList.remove("animate-spin");
  }

  if (container) {
    const panel = document.getElementById(container);
    if (panel && spin) {
      panel.classList.add("hidden");
    }

    if (panel && !spin) {
      panel.classList.remove("hidden");
    }
  }
};

// Sliding Panel Functions
window.openSlidingPanel = function () {
  const overlay = document.getElementById("panelOverlay");
  const panel = document.getElementById("slidingPanel");

  if (overlay && panel) {
    overlay.classList.add("active");
    panel.classList.add("active");
    document.body.style.overflow = "hidden"; // Prevent background scrolling
  }
};

window.closeSlidingPanel = function () {
  const overlay = document.getElementById("panelOverlay");
  const panel = document.getElementById("slidingPanel");

  if (overlay && panel) {
    overlay.classList.remove("active");
    panel.classList.remove("active");
    document.body.style.overflow = ""; // Restore scrolling
  }
};

window.switchToTab = function (tabId) {
  // Remove active class from all tabs
  const tabs = document.querySelectorAll(".tab");
  const panels = document.querySelectorAll('[role="tabpanel"]');

  tabs.forEach((tab) => {
    tab.setAttribute("aria-selected", "false");
    tab.classList.remove("active");
  });

  panels.forEach((panel) => {
    panel.setAttribute("hidden", "");
    panel.setAttribute("aria-selected", "false");
  });

  // Activate the selected tab
  const selectedTab = document.getElementById(tabId);
  const panelId = selectedTab.getAttribute("aria-controls");
  const selectedPanel = document.getElementById(panelId);

  if (selectedTab && selectedPanel) {
    selectedTab.setAttribute("aria-selected", "true");
    selectedTab.classList.add("active");
    selectedPanel.removeAttribute("hidden");
    selectedPanel.setAttribute("aria-selected", "true");

    // Trigger any HTMX requests if needed
    if (selectedTab.hasAttribute("hx-get")) {
      selectedTab.click();
    }
  }
};

// Close panel on Escape key
document.addEventListener("keydown", function (event) {
  if (event.key === "Escape") {
    closeSlidingPanel();
  }
});
