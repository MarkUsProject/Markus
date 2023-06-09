const FLASH_KEYS = ["notice", "warning", "success", "error"];
export function renderFlashForFetch(headers) {
  let discard = [];
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
}

window.fetch = new Proxy(window.fetch, {
  apply(fetch, that, args) {
    // Forward function call to the original fetch
    const result = fetch.apply(that, args);

    // Render flash with the resulting Promise
    result.then(response => {
      let headers = response.headers;
      renderFlashForFetch(headers);
    });
    return result;
  },
});
