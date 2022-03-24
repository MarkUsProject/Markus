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
