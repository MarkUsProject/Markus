import {fireEvent, render, screen, within} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import {AnnotationTable} from "../Result/annotation_table";
import {defaultSearchPlaceholderText} from "../table/search_filter";
import safe_marked from "../../common/safe_marked";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => <span />,
}));

global.safe_marked = safe_marked;

function makeAnnotation(attrs = {}) {
  return {
    id: 1,
    number: 1,
    filename: "a.py",
    path: "src",
    submission_file_id: 10,
    line_start: 3,
    content: "Annotation text",
    creator: "Instructor",
    annotation_category: "Style",
    is_remark: false,
    deduction: null,
    criterion_name: null,
    ...attrs,
  };
}

function renderAnnotationTable(props = {}) {
  const allProps = {
    annotations: [makeAnnotation()],
    detailed: false,
    released_to_students: false,
    remark_submitted: false,
    editAnnotation: jest.fn(),
    removeAnnotation: jest.fn(),
    selectFile: jest.fn(),
    ...props,
  };
  return {...render(<AnnotationTable {...allProps} />), props: allProps};
}

function columnHeaders() {
  return screen.getAllByRole("columnheader").map(header => header.textContent);
}

function annotationNumbers(container) {
  return Array.from(container.querySelectorAll(".rt-tbody .rt-tr")).map(
    row => within(row).getAllByRole("gridcell")[0].textContent
  );
}

const filenameHeader = () => I18n.t("attributes.filename");
const deductionHeader = () => I18n.t("activerecord.attributes.annotation_text.deduction");
const creatorHeader = () => I18n.t("activerecord.attributes.annotation.creator");
const categoryHeader = () => I18n.t("activerecord.models.annotation_category", {count: 1});
const remarkFlag = () => `(${I18n.t("results.annotation.remark_flag")})`;

describe("AnnotationTable", () => {
  describe("columns", () => {
    it("shows the number, filename and text columns", () => {
      renderAnnotationTable();

      expect(columnHeaders()).toEqual(
        expect.arrayContaining(["#", filenameHeader(), I18n.t("annotations.text")])
      );
      expect(screen.queryByText(creatorHeader())).not.toBeInTheDocument();
      expect(screen.queryByText(categoryHeader())).not.toBeInTheDocument();
      expect(screen.queryByText(deductionHeader())).not.toBeInTheDocument();
    });

    it("shows the creator and category columns when detailed", () => {
      renderAnnotationTable({detailed: true});

      expect(columnHeaders()).toEqual(expect.arrayContaining([creatorHeader(), categoryHeader()]));
      expect(screen.getByText("Instructor")).toBeInTheDocument();
      expect(screen.getByText("Style")).toBeInTheDocument();
    });

    it("shows the deduction column when an annotation has a deduction", () => {
      const {container} = renderAnnotationTable({
        annotations: [makeAnnotation({deduction: 2, criterion_name: "Q1"})],
      });

      expect(screen.getByText(deductionHeader())).toBeInTheDocument();
      expect(screen.getByText("[Q1]", {exact: false})).toBeInTheDocument();
      expect(container.querySelector(".red-text")).toHaveTextContent("-2");
    });

    it("adds the deduction column when an annotation with a deduction is added", () => {
      const {props, rerender} = renderAnnotationTable();
      expect(screen.queryByText(deductionHeader())).not.toBeInTheDocument();

      rerender(
        <AnnotationTable
          {...props}
          annotations={[
            makeAnnotation(),
            makeAnnotation({id: 2, deduction: 1, criterion_name: "Q1"}),
          ]}
        />
      );
      expect(screen.getByText(deductionHeader())).toBeInTheDocument();
    });
  });

  describe("cells", () => {
    it("selects the annotation's file and line when its filename is clicked", async () => {
      const {props} = renderAnnotationTable();

      await userEvent.click(
        screen.getByText(
          I18n.t("results.annotation.filename_with_line", {filename: "src/a.py", line: 3})
        )
      );
      expect(props.selectFile).toHaveBeenCalledWith("src/a.py", 10, 3, 1);
    });

    it("shows only the filename for a file at the top of the submission", () => {
      renderAnnotationTable({
        annotations: [makeAnnotation({path: null, line_start: undefined})],
      });

      expect(screen.getByText("a.py")).toBeInTheDocument();
    });

    it("renders the annotation text as markdown", () => {
      const {container} = renderAnnotationTable({
        annotations: [makeAnnotation({content: "**important**"})],
      });

      expect(container.querySelector("strong")).toHaveTextContent("important");
    });

    it("renders math in the annotation text", () => {
      const {container} = renderAnnotationTable({
        annotations: [makeAnnotation({content: "$x^2$"})],
      });

      expect(container.querySelector(".katex")).toBeInTheDocument();
    });

    it("renders math again when the annotation text changes", () => {
      const {container, props, rerender} = renderAnnotationTable();
      expect(container.querySelector(".katex")).toBeNull();

      rerender(<AnnotationTable {...props} annotations={[makeAnnotation({content: "$y$"})]} />);
      expect(container.querySelector(".katex")).toBeInTheDocument();
    });

    it("keeps the rendered math when an unchanged annotation is rendered again", () => {
      const annotation = makeAnnotation({content: "$x^2$"});
      const {container, props, rerender} = renderAnnotationTable({annotations: [annotation]});

      rerender(<AnnotationTable {...props} annotations={[{...annotation}]} />);
      expect(container.querySelector(".katex")).toBeInTheDocument();
      expect(screen.queryByText("$x^2$", {exact: false})).not.toBeInTheDocument();
    });

    it("renders each annotation's text in its own preview", () => {
      const {container} = renderAnnotationTable({
        annotations: [
          makeAnnotation({id: 1, number: 1, content: "**first** $a$"}),
          makeAnnotation({id: 2, number: 2, content: "_second_ $b$"}),
        ],
      });

      const first = container.querySelector("#annotation-preview-1");
      const second = container.querySelector("#annotation-preview-2");
      expect(first.querySelector("strong")).toHaveTextContent("first");
      expect(first.querySelector(".katex")).toBeInTheDocument();
      expect(second.querySelector("em")).toHaveTextContent("second");
      expect(second.querySelector(".katex")).toBeInTheDocument();
      expect(container.querySelector("#annotation-preview")).toBeNull();
    });

    it("sanitizes the annotation text", () => {
      const {container} = renderAnnotationTable({
        annotations: [
          makeAnnotation({content: '<img src="x" onerror="alert(1)"><script>x</script>'}),
        ],
      });

      const preview = container.querySelector("#annotation-preview-1");
      expect(preview.querySelector("script")).toBeNull();
      expect(preview.querySelector("img")).not.toHaveAttribute("onerror");
    });

    it("renders math in only the edited annotation's preview", () => {
      const annotations = [
        makeAnnotation({id: 1, number: 1, content: "$a$"}),
        makeAnnotation({id: 2, number: 2, content: "plain"}),
      ];
      const {container, props, rerender} = renderAnnotationTable({annotations});

      rerender(
        <AnnotationTable
          {...props}
          annotations={[annotations[0], {...annotations[1], content: "**edited** $b$"}]}
        />
      );
      const first = container.querySelector("#annotation-preview-1");
      const second = container.querySelector("#annotation-preview-2");
      expect(first.querySelectorAll(".katex")).toHaveLength(1);
      expect(second.querySelector("strong")).toHaveTextContent("edited");
      expect(second.querySelectorAll(".katex")).toHaveLength(1);
    });

    it("flags remark annotations in the text and creator columns", () => {
      renderAnnotationTable({
        detailed: true,
        annotations: [makeAnnotation({is_remark: true})],
      });

      expect(screen.getByText(`Annotation text ${remarkFlag()}`)).toBeInTheDocument();
      expect(screen.getByText(`Instructor ${remarkFlag()}`)).toBeInTheDocument();
    });
  });

  describe("edit and delete buttons", () => {
    it("deletes the annotation when its delete button is clicked", async () => {
      const {props} = renderAnnotationTable();

      await userEvent.click(screen.getByTitle(I18n.t("delete")));
      expect(props.removeAnnotation).toHaveBeenCalledWith(1);
    });

    it("edits the annotation when its edit button is clicked", async () => {
      const {props} = renderAnnotationTable();

      await userEvent.click(screen.getByTitle(I18n.t("edit")));
      expect(props.editAnnotation).toHaveBeenCalledWith(1);
    });

    it("does not show an edit button for an annotation with a deduction", () => {
      renderAnnotationTable({
        annotations: [makeAnnotation({deduction: 2, criterion_name: "Q1"})],
      });

      expect(screen.getByTitle(I18n.t("delete"))).toBeInTheDocument();
      expect(screen.queryByTitle(I18n.t("edit"))).not.toBeInTheDocument();
    });

    it.each([
      ["the result is released", {released_to_students: true}],
      ["a remark request is submitted", {remark_submitted: true}],
    ])("does not show edit or delete buttons when %s", (_, props) => {
      renderAnnotationTable(props);

      expect(screen.queryByTitle(I18n.t("delete"))).not.toBeInTheDocument();
      expect(screen.queryByTitle(I18n.t("edit"))).not.toBeInTheDocument();
    });

    it("removes the edit and delete buttons when the result is released", () => {
      const {props, rerender} = renderAnnotationTable();
      expect(screen.getByTitle(I18n.t("delete"))).toBeInTheDocument();

      rerender(<AnnotationTable {...props} released_to_students={true} />);
      expect(screen.queryByTitle(I18n.t("delete"))).not.toBeInTheDocument();
      expect(screen.queryByTitle(I18n.t("edit"))).not.toBeInTheDocument();
    });
  });

  describe("sorting", () => {
    const annotations = [
      makeAnnotation({id: 1, number: 1, filename: "b.py"}),
      makeAnnotation({id: 2, number: 2, filename: "a.py", deduction: 1, criterion_name: "Q2"}),
      makeAnnotation({id: 3, number: 3, filename: "a.py"}),
      makeAnnotation({id: 4, number: 4, filename: "c.py", deduction: 2, criterion_name: "Q1"}),
      makeAnnotation({id: 5, number: 5, filename: "a.py"}),
    ];

    it("sorts by deduction, then filename, then number, with no deduction last", () => {
      const {container} = renderAnnotationTable({annotations});

      expect(annotationNumbers(container)).toEqual(["4", "2", "3", "5", "1"]);
    });

    it("sorts by filename, then number, when there are no deductions", () => {
      const {container} = renderAnnotationTable({
        annotations: annotations.map(a => ({...a, deduction: null})),
      });

      expect(annotationNumbers(container)).toEqual(["2", "3", "5", "1", "4"]);
    });

    it("sorts by deduction when the annotations are loaded after the table is rendered", () => {
      const {container, props, rerender} = renderAnnotationTable({annotations: []});

      rerender(<AnnotationTable {...props} annotations={annotations} />);
      expect(annotationNumbers(container)).toEqual(["4", "2", "3", "5", "1"]);
    });
  });

  describe("filtering", () => {
    const annotations = [
      makeAnnotation({id: 1, number: 1, filename: "main.py", content: "Good work"}),
      makeAnnotation({id: 2, number: 2, filename: "helper.py", content: "Needs tests"}),
      makeAnnotation({id: 12, number: 12, filename: "main.py", annotation_category: null}),
    ];

    it("filters by number", async () => {
      const {container} = renderAnnotationTable({annotations});

      await userEvent.type(
        screen.getByRole("textbox", {name: defaultSearchPlaceholderText("#")}),
        "2"
      );
      expect(annotationNumbers(container)).toEqual(["2", "12"]);
    });

    it("filters by category when the first annotation has no category", async () => {
      const {container} = renderAnnotationTable({
        detailed: true,
        annotations: [annotations[2], annotations[0], annotations[1]],
      });

      await userEvent.type(
        screen.getByRole("textbox", {name: defaultSearchPlaceholderText(categoryHeader())}),
        "sty"
      );
      expect(annotationNumbers(container)).toEqual(["2", "1"]);
    });

    it("filters by deduction", async () => {
      const {container} = renderAnnotationTable({
        annotations: [
          makeAnnotation({id: 1, number: 1, deduction: 1, criterion_name: "Correctness"}),
          makeAnnotation({id: 2, number: 2, deduction: 2, criterion_name: "Style"}),
          makeAnnotation({id: 3, number: 3}),
        ],
      });

      await userEvent.type(
        screen.getByRole("textbox", {name: defaultSearchPlaceholderText(deductionHeader())}),
        "correct"
      );
      expect(annotationNumbers(container)).toEqual(["1"]);
    });
  });

  it("renders math in rows that are shown after scrolling a large table", () => {
    const rowHeight = 34;
    const offsetHeight = jest.spyOn(HTMLElement.prototype, "offsetHeight", "get");
    offsetHeight.mockReturnValue(rowHeight);
    const clientHeight = jest.spyOn(HTMLElement.prototype, "clientHeight", "get");
    clientHeight.mockReturnValue(340);

    try {
      const annotations = Array.from({length: 200}, (_, index) =>
        makeAnnotation({id: index + 1, number: index + 1, content: `Annotation ${index + 1} $x$`})
      );
      const {container} = renderAnnotationTable({annotations});
      expect(screen.queryByText("Annotation 150", {exact: false})).not.toBeInTheDocument();

      const body = container.querySelector(".rt-tbody");
      fireEvent.scroll(body, {target: {scrollTop: 150 * rowHeight}});

      const cell = screen.getByText("Annotation 150", {exact: false}).closest('[role="gridcell"]');
      expect(cell.querySelector(".katex")).toBeInTheDocument();
    } finally {
      clientHeight.mockRestore();
      offsetHeight.mockRestore();
    }
  });
});
