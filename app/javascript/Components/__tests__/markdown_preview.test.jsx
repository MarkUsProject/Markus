import {render} from "@testing-library/react";

import MarkdownPreview from "../markdown_preview";

describe("MarkdownPreview", () => {
  it("uses the default id and class when none are given", () => {
    const {container} = render(<MarkdownPreview content="**bold**" />);

    const preview = container.firstChild;
    expect(preview).toHaveAttribute("id", "annotation-preview");
    expect(preview).toHaveClass("preview");
    expect(preview.querySelector("strong")).toHaveTextContent("bold");
  });

  it("uses the id and class it is given", () => {
    const {container} = render(<MarkdownPreview id="custom-preview" className="" content="text" />);

    const preview = container.firstChild;
    expect(preview).toHaveAttribute("id", "custom-preview");
    expect(preview).not.toHaveClass("preview");
  });

  it("renders math in its own element when there are several previews", () => {
    const {container} = render(
      <>
        <MarkdownPreview id="first" content="$a$" />
        <MarkdownPreview id="second" content="$b$" />
      </>
    );

    expect(container.querySelector("#first .katex")).toBeInTheDocument();
    expect(container.querySelector("#second .katex")).toBeInTheDocument();
  });

  it("renders math again when the content changes", () => {
    const {container, rerender} = render(<MarkdownPreview content="plain" />);
    expect(container.querySelector(".katex")).toBeNull();

    rerender(<MarkdownPreview content="$x^2$" />);
    expect(container.querySelector(".katex")).toBeInTheDocument();
  });

  it("keeps the rendered math when it is rendered again with the same content", () => {
    const {container, rerender} = render(<MarkdownPreview content="$x^2$" />);

    rerender(<MarkdownPreview content="$x^2$" />);
    expect(container.querySelector(".katex")).toBeInTheDocument();
    expect(container).not.toHaveTextContent("$x^2$");
  });
});
