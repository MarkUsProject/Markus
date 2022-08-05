/*
 * Used to setup the Jest environment
 * https://jestjs.io/docs/configuration#setupfiles-array
 */

// jquery
import $ from "jquery";
window.$ = window.jQuery = global.jQuery = global.$ = $;

// i18n-js
import * as I18n from "i18n-js";
import "translations";
window.I18n = I18n;
