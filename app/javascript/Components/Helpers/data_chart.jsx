import React from "react";
import {createRoot} from "react-dom/client";
import {Bar} from "react-chartjs-2";
import {chartScales} from "./chart_helpers";

export function makeDataChart(elem, {labels, datasets, xTitle, yTitle, legend = false}) {
  const root = createRoot(elem);
  root.render(
    <Bar
      data={{labels, datasets}}
      options={{
        responsive: true,
        maintainAspectRatio: false,
        plugins: {legend: {display: legend}},
        scales: chartScales(xTitle, yTitle),
      }}
      style={{margin: "10px"}}
    />
  );
}
