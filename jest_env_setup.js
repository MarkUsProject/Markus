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
