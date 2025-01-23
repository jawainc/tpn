/**
 * remove options from a select element
 * @param {*} id
 */
export function selectRemoveOptions(arg) {
  console.log("selectRemoveOptions >>>>>>", arg);
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
}

/**
 * trigger events
 * @param {*} events
 */
export function triggerEvent(value, event, type, elm = "") {
  switch (event) {
    case "load_wards":
      load_wards(value, type, elm);
      break;
    case "load_rooms":
      load_rooms(value, elm);
      break;
    case "load_beds":
      load_beds(value, elm);
      break;
    case "load_template_formularies":
      load_template_formularies();
      break;
    default:
      document.body.dispatchEvent(new CustomEvent(event, { detail: value }));
  }
}

/**
 * adds/removes a class to an element based on the checked state of a checkbox
 * @param {*} element
 */
export function applyCheckboxSelector(element) {
  if (element.querySelector("input").checked) {
    element.classList.add("checkox-checked-indicator");
  } else {
    element.classList.remove("checkox-checked-indicator");
  }
}

function load_wards(value, type, elm) {
  if (!value) {
    selectRemoveOptions(elm + "_ward_id");
    return;
  }

  document.body.dispatchEvent(new CustomEvent("load_wards", { detail: { id: value, type: type } }));
}

function load_rooms(value, elm) {
  console.log("load rooms >>>>>>", elm);
  if (!value) {
    selectRemoveOptions(elm + "_room_id");
    return;
  }
  document.body.dispatchEvent(new CustomEvent("load_rooms", { detail: { id: value } }));
}

function load_beds(value, elm) {
  console.log("load beds >>>>>>", elm);
  if (!value) {
    selectRemoveOptions(elm + "_bed_id");
    return;
  }
  document.body.dispatchEvent(new CustomEvent("load_beds", { detail: { id: value } }));
}

function load_template_formularies(value) {
  const template_id = document.getElementById("template_product_template_id").value;
  const class_id = document.getElementById("template_product_class_id").value;

  if (!template_id || !class_id) {
    selectRemoveOptions("template_product_formulary_id");
    return;
  }

  document.body.dispatchEvent(
    new CustomEvent("load_template_formularies", {
      detail: {
        template_id: template_id,
        class_id: class_id,
      },
    }),
  );
}
