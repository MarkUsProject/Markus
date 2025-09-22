/*
 * Used for global imports before each test file is run (but after the Jest Environment is set up)
 * https://jestjs.io/docs/configuration#setupfilesafterenv-array
 */

// React
import React from "react";
global.React = React;

// Jest dom (testing env)
import "@testing-library/jest-dom";

// Routes
window.Routes = global.Routes = require("./app/javascript/routes");

// Jest fetch mock
require("jest-fetch-mock").enableMocks();

// Define HTMLElement.prototype.offsetParent
// Code from https://github.com/jsdom/jsdom/issues/1261#issuecomment-1765404346
Object.defineProperty(HTMLElement.prototype, "offsetParent", {
  get() {
    // eslint-disable-next-line @typescript-eslint/no-this-alias
    for (let element = this; element; element = element.parentNode) {
      if (element.style?.display?.toLowerCase() === "none") {
        return null;
      }
    }

    if (this.stye?.position?.toLowerCase() === "fixed") {
      return null;
    }

    if (this.tagName.toLowerCase() in ["html", "body"]) {
      return null;
    }

    return this.parentNode;
  },
});

// Ensure icons are defined
import "./app/javascript/common/fontawesome_config";

// Ensure App element is defined for react-modal
import Modal from "react-modal";
beforeAll(() => Modal.setAppElement("body"));

// Set up MathJax
global.MathJax = {
  startup: {
    typeset: false,
  },
  tex: {
    // Allow inline single dollar sign notation
    inlineMath: [
      ["$", "$"],
      ["\\(", "\\)"],
    ],
    processEnvironments: true,
    processRefs: false,
  },
  options: {
    ignoreHtmlClass: "tex2jax_ignore",
    processHtmlClass: "tex2jax_process",
  },
  svg: {
    fontCache: "global",
  },
};

// Mock MathJax.typeset. TODO: Get MathJax to load properly in tests
global.MathJax.typeset = jest.fn();
import "mathjax/es5/tex-svg";

// Originally defined in app/assets/javascripts/Grader/marking.js
global.activeCriterion = jest.fn();

// Ensure @testing-library/react cleanup function is called after every test
import {cleanup} from "@testing-library/react";
afterEach(cleanup);

import {
  customLoadingProp,
  customNoDataComponent,
  customNoDataProps,
} from "/app/javascript/Components/Helpers/table_helpers";
import {ReactTableDefaults} from "react-table";

Object.assign(ReactTableDefaults, {
  NoDataComponent: customNoDataComponent,
  noDataProps: customNoDataProps,
  LoadingComponent: customLoadingProp,
});
