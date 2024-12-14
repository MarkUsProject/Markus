import {renderFlash} from "./ajax_events";

window.fetch = new Proxy(window.fetch, {
  apply(fetch, that, args) {
    // Forward function call to the original fetch
    const result = fetch.apply(that, args);

    // Render flash with the resulting Promise
    result.then(response => {
      let headers = response.headers;
      renderFlash(null, null, headers);
    });
    return result;
  },
});
