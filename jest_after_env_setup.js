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

// Enzyme configuration
import {configure} from "enzyme";
import Adapter from "enzyme-adapter-react-16";

configure({adapter: new Adapter()});

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
