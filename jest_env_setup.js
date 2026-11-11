/*
 * Used to setup the Jest environment
 * https://jestjs.io/docs/configuration#setupfiles-array
 */

// jquery
import $ from "jquery";
window.$ = window.jQuery = global.jQuery = global.$ = $;

import {deserialize, serialize} from "v8";

// i18n-js
import {I18n} from "i18n-js";
import translations from "translations.json";
window.I18n = new I18n(translations);

// jsdom has no structuredClone (@rjsf/core uses it)
global.structuredClone ??= value => deserialize(serialize(value));

// jsdom has no ResizeObserver
global.ResizeObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
};

global.DOCS_URL = "http://localhost:4000";
global.RELATIVE_URL_ROOT = "";
