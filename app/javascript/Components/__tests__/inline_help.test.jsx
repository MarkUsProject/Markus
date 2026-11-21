import InlineHelp from "../Helpers/inline_help";
import {render, screen, fireEvent} from "@testing-library/react";

describe("InlineHelp", () => {
  let container;

  beforeEach(() => {
    ({container} = render(<InlineHelp>Some help text</InlineHelp>));
  });

  it("renders a help icon", () => {
    expect(container.querySelector(".inline-help svg.fa-circle-question")).toBeInTheDocument();
  });

  it("hides the help text initially", () => {
    expect(screen.getByText("Some help text")).not.toBeVisible();
  });

  it("shows the help text when clicked", () => {
    fireEvent.click(container.querySelector(".inline-help"));
    expect(screen.getByText("Some help text")).toBeVisible();
  });

  it("hides the help text when clicked again", () => {
    const help = container.querySelector(".inline-help");
    fireEvent.click(help);
    fireEvent.click(help);
    expect(screen.getByText("Some help text")).not.toBeVisible();
  });
});
