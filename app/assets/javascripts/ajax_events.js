const FLASH_KEYS = ["notice", "warning", "success", "error"];

/*
 * Display flash messages sent in response to an AJAX request.
 * If a message key is in the X-Message-Discard header, hide
 * it instead.
 */
export function renderFlash(event, request) {
  // For rails/ujs, request is stored in event.
  if (request === undefined) {
    request = event.detail[0];
  }
  let discard = [];
  const discardMessage = request.getResponseHeader("X-Message-Discard");
  if (discardMessage) {
    discard = discardMessage.split(";");
  }
  FLASH_KEYS.forEach(key => {
    const flashDiv = document.getElementsByClassName(key)[0];
    if (flashDiv === undefined) {
      return;
    }
    if (discard.includes(key)) {
      flashDiv.style.display = "none";
    } else {
      const flashMessage = request.getResponseHeader(`X-Message-${key}`);
      if (flashMessage) {
        const messages = flashMessage.split(";");
        const contents = flashDiv.getElementsByClassName("flash-content")[0] || flashDiv;
        contents.innerHTML = "";
        if (messages.length) {
          messages.forEach(message => {
            contents.insertAdjacentHTML("beforeend", message);
          });
          flashDiv.style.display = "block";
        } else {
          flashDiv.style.display = "none";
        }
      }
    }
  });
}

/*
 * Hide all flash message divs. Typically used when a new non-GET request is sent.
 */
export function hideFlash() {
  FLASH_KEYS.forEach(key => {
    for (let elem of document.getElementsByClassName(key)) {
      elem.style.display = "none";
      const contents = elem.getElementsByClassName("flash-content")[0] || elem;
      contents.innerHTML = "";
    }
  });
}

/*
 * Register global callbacks for both rails/ujs and jQuery.
 */
document.addEventListener("DOMContentLoaded", () => {
  let elem = document.body;
  elem.addEventListener("ajax:complete", renderFlash);

  elem.addEventListener("ajax:beforeSend", event => {
    const settings = event.detail[1];
    if (settings.type.toUpperCase() !== "GET") {
      hideFlash();
    }
  });
});

$(document).ajaxSend((event, request, settings) => {
  if (settings.type.toUpperCase() !== "GET") {
    hideFlash();
  }
});

$(document).ajaxComplete(renderFlash);

window.fetch = new Proxy(window.fetch, {
  apply(fetch, that, args) {
    // Forward function call to the original fetch
    const result = fetch.apply(that, args);

    // Do whatever you want with the resulting Promise
    result.then(response => {
      let discard = [];
      let headers = response.headers;
      const discardMessage = headers.get("X-Message-Discard");
      if (discardMessage) {
        discard = discardMessage.split(";");
      }
      FLASH_KEYS.forEach(key => {
        const flashDiv = document.getElementsByClassName(key)[0];
        if (flashDiv === undefined) {
          return;
        }
        if (discard.includes(key)) {
          flashDiv.style.display = "none";
        } else {
          const flashMessage = headers.get(`X-Message-${key}`);
          if (flashMessage) {
            const messages = flashMessage.split(";");
            const contents = flashDiv.getElementsByClassName("flash-content")[0] || flashDiv;
            contents.innerHTML = "";
            if (messages.length) {
              messages.forEach(message => {
                contents.insertAdjacentHTML("beforeend", message);
              });
              flashDiv.style.display = "block";
            } else {
              flashDiv.style.display = "none";
            }
          }
        }
      });
    });

    return result;
  },
});
