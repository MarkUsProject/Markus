/*
 * Used to setup the Jest environment
 * https://jestjs.io/docs/configuration#setupfiles-array
 */

// jquery
import $ from "jquery";
window.$ = window.jQuery = global.jQuery = global.$ = $;

// i18n-js
import {I18n} from "i18n-js";
import translations from "translations.json";
window.I18n = new I18n(translations);

// jsdom has no ResizeObserver
global.ResizeObserver = class {
  observe() {}
  disconnect() {}
};

global.DOCS_URL = "http://localhost:4000";
global.RELATIVE_URL_ROOT = "";
