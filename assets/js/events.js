export function events(params) {
  document.body.addEventListener("clientObey", function (evt) {
    const dispatchEvent = evt.detail.event || null;
    const status = evt.detail.status || null;
    const message = evt.detail.message || null;
    // Show snackbar if needed
    if (status) {
      new SnackBar({
        message: message,
        status: status,
        timeout: 5000,
      });
    }

    // Dispatch event if needed
    if (dispatchEvent) {
      document.body.dispatchEvent(new CustomEvent(dispatchEvent, { detail: {} }));
    }
  });

  document.body.addEventListener("xKey", function (evt) {
    const status = evt.detail.vek || null;
    const message = evt.detail.vec || null;

    if (status) {
      localStorage.setItem("x-key-status", status);
    }

    if (message) {
      localStorage.setItem("x-key-message", message);
    }
  });

  document.body.addEventListener("htmx:beforeSwap", async function (evt) {
    evt.detail.shouldSwap = false;
  });

  document.body.addEventListener("htmx:afterRequest", async function (evt) {
    try {
      if (evt.detail.xhr.status !== 204) {
        const key = localStorage.getItem("x-key-status");
        const iv = localStorage.getItem("x-key-message");

        // clear iv from local storage
        localStorage.removeItem("x-key-message");

        if (key && iv) {
          const body = await decryptData(evt.detail.xhr.response, key, iv);
          htmx.swap(evt.detail.target, body, { swapStyle: "innerHTML" });
        } else {
          htmx.swap(evt.detail.target, evt.detail.xhr.response, { swapStyle: "innerHTML" });
        }
      }
    } catch (error) {
      console.log(error);
    }
  });
}

export async function formConfigRequest(evt) {
  try {
    if (evt.detail.verb === "get") {
      return;
    }

    evt.preventDefault();
    const key = localStorage.getItem("x-key-status");

    if ((key && evt.detail.verb === "post") || evt.detail.verb === "put") {
      const formData = new FormData(evt.detail.elt);
      // get _csrf_token from the form
      const csrfToken = formData.get("_csrf_token");
      // remove _csrf_token from the form
      formData.delete("_csrf_token");
      // get _method from the form
      const method = formData.get("_method");
      // remove _method from the form
      formData.delete("_method");
      const plainText = new URLSearchParams(formData).toString();

      // Encrypt the form data
      const { iv, encryptedData } = await encryptData(plainText, key);

      const values = {
        _csrf_token: csrfToken,
        data: encryptedData,
      };

      if (method) {
        values._method = method;
      }

      htmx.ajax("POST", evt.detail.path, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Hx-Key": iv,
        },
        values: values,
        target: evt.detail.target,
      });
    }
  } catch (error) {
    console.log(error);
  }
}

// Import the necessary functions from the Web Crypto API
async function decryptData(encryptedData, key, iv) {
  try {
    // Convert the key and IV from Base64 to ArrayBuffer
    const keyBuffer = Uint8Array.from(atob(key), (c) => c.charCodeAt(0));
    const ivBuffer = Uint8Array.from(atob(iv), (c) => c.charCodeAt(0));
    const encryptedBuffer = Uint8Array.from(atob(encryptedData), (c) => c.charCodeAt(0));

    // Import the key
    const cryptoKey = await window.crypto.subtle.importKey("raw", keyBuffer, { name: "AES-CBC" }, false, ["decrypt"]);

    // Decrypt the data
    const decryptedBuffer = await window.crypto.subtle.decrypt(
      {
        name: "AES-CBC",
        iv: ivBuffer,
      },
      cryptoKey,
      encryptedBuffer,
    );

    // Convert the decrypted ArrayBuffer to a string
    const decoder = new TextDecoder();
    return decoder.decode(decryptedBuffer);
  } catch (error) {
    console.log(error);
  }
}

// Import the necessary functions from the Web Crypto API
async function encryptData(data, key) {
  const keyBuffer = Uint8Array.from(atob(key), (c) => c.charCodeAt(0));
  const iv = window.crypto.getRandomValues(new Uint8Array(16));
  const ivBase64 = btoa(String.fromCharCode(...iv));

  const cryptoKey = await window.crypto.subtle.importKey("raw", keyBuffer, { name: "AES-CBC" }, false, ["encrypt"]);

  const encoder = new TextEncoder();
  const dataBuffer = encoder.encode(data);

  const encryptedBuffer = await window.crypto.subtle.encrypt(
    {
      name: "AES-CBC",
      iv: iv,
    },
    cryptoKey,
    dataBuffer,
  );

  const encryptedData = btoa(String.fromCharCode(...new Uint8Array(encryptedBuffer)));

  return { iv: ivBase64, encryptedData };
}
