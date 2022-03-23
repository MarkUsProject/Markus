// React
import React from "react";
global.React = React;

// Jest dom (testing env)
import "@testing-library/jest-dom";

// Routes
window.Routes = global.Routes = require("./app/javascript/routes");
