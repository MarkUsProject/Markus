import * as React from "react";
import {render, screen, fireEvent, within} from "@testing-library/react";
import ReactTable from "react-table";

describe("Default React Table", () => {
  it("shows the default no data text when no data is provided", async () => {
    render(<ReactTable columns={[]} data={[]} />);
    await screen.findByText("No rows found");
  });

  it("shows a custom no data text when set", async () => {
    const customNoDataText = "custom no data text";
    render(<ReactTable columns={[]} data={[]} noDataText={customNoDataText} />);
    await screen.findByText(customNoDataText);
  });
});
