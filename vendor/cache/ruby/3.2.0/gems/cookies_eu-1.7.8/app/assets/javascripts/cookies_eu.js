//= require js.cookie
'use strict';

var windowIsTurbolinked = 'Turbolinks' in window;

var cookiesEu = {
  init: function() {
    var cookiesEuOKButton = document.querySelector('.js-cookies-eu-ok');

    if (cookiesEuOKButton) {
      this.addListener(cookiesEuOKButton);
      // clear turbolinks cache so cookie banner does not reappear
      windowIsTurbolinked && window.Turbolinks.clearCache();
    }
  },

  addListener: function(target) {
    // Support for IE < 9
    if (target.attachEvent) {
      target.attachEvent('onclick', this.setCookie);
    } else {
      target.addEventListener('click', this.setCookie, false);
    }
  },

  setCookie: function() {
    var isSecure = location.protocol === 'https:';
    Cookies.set('cookie_eu_consented', true, { path: '/', expires: 365, secure: isSecure });

    var container = document.querySelector('.js-cookies-eu');
    container.parentNode.removeChild(container);

    document.dispatchEvent(new CustomEvent('cookies-eu-acknowledged'));
  }
};

(function() {
  function eventName(fallback) {
    return windowIsTurbolinked ? 'turbolinks:load' : fallback
  }

  var isCalled = false;

  function isReady() {
    // return early when cookiesEu.init has been called AND Turbolinks is NOT included
    // when Turbolinks is included cookiesEu.init has to be called on every page load
    if (isCalled && !windowIsTurbolinked) {
      return
    }
    isCalled = true;

    cookiesEu.init();
  }

  if (document.addEventListener) {
    return document.addEventListener(eventName('DOMContentLoaded'), isReady, false);
  }

  // Old browsers IE < 9
  if (window.addEventListener) {
    window.addEventListener(eventName('load'), isReady, false);
  } else if (window.attachEvent) {
    window.attachEvent(eventName('onload'), isReady);
  }
})();
