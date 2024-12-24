import {renderFlash} from "./ajax_events";

window.fetch = new Proxy(window.fetch, {
  apply(fetch, that, args) {
    let [resource, options] = args;

    // Set the X-Requested-With header to make Rails request.xhr? method return true.
    // See https://github.com/rails/rails/issues/21709
    if (!!options) {
      options = {
        headers: {"X-Requested-With": "XMLHttpRequest"},
      };
    } else {
      options = {...options};
      if (options.hasOwnProperty("headers")) {
        options.headers["X-Requested-With"] = "XMLHttpRequest";
      } else {
        options.headers = {"X-Requested-With": "XMLHttpRequest"};
      }
    }
    // Forward function call to the original fetch
    const result = fetch.apply(that, [resource, options]);

    // Render flash with the resulting Promise
    result.then(response => {
      let headers = response.headers;
      renderFlash(null, null, headers);
    });
    return result;
  },
});
