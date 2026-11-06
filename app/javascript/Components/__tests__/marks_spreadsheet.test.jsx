/***
 * Tests for MarksSpreadsheet and GradeEntryCell Components
 */

import {MarksSpreadsheet, GradeEntryCell} from "../marks_spreadsheet";
import {render, screen, fireEvent, act, waitFor, within} from "@testing-library/react";
import {expect} from "@jest/globals";

describe("GradeEntryCell", () => {
  let props, requests;

  const renderCell = (overrides = {}) => <GradeEntryCell {...props} {...overrides} />;

  beforeEach(() => {
    jest.useFakeTimers();
    requests = [];
    jest.spyOn($, "ajax").mockImplementation(() => {
      const deferred = $.Deferred();
      requests.push(deferred);
      return deferred.promise();
    });
    props = {
      course_id: 1,
      grade_entry_form_id: 1,
      grade_id: "grade_1_1",
      grade_entry_column: "1",
      bonus: false,
      student_id: 1,
      default_value: 3,
      updateTotal: jest.fn(),
    };
  });

  afterEach(() => {
    jest.restoreAllMocks();
    jest.useRealTimers();
  });

  const enterGrade = value => {
    fireEvent.change(screen.getByRole("spinbutton"), {target: {value}});
    act(() => {
      jest.advanceTimersByTime(300);
    });
  };

  // jQuery runs .then callbacks asynchronously, so advance timers after resolving the request
  const respond = (request, total) => {
    act(() => {
      request.resolve(total);
      jest.runOnlyPendingTimers();
    });
  };

  it("keeps a saved grade when re-rendered with unchanged row data", () => {
    const {rerender} = render(renderCell());
    enterGrade("5");
    respond(requests[0], "5");

    rerender(renderCell());

    expect(screen.getByRole("spinbutton")).toHaveValue(5);
  });

  it("updates the grade when the row data changes", () => {
    const {rerender} = render(renderCell());

    rerender(renderCell({default_value: 7}));

    expect(screen.getByRole("spinbutton")).toHaveValue(7);
  });

  it("resets the grade when the cell is reused for a different student", () => {
    const {rerender} = render(renderCell());
    enterGrade("5");

    rerender(renderCell({student_id: 2, grade_id: "grade_2_1"}));

    expect(screen.getByRole("spinbutton")).toHaveValue(3);
  });

  it("ignores responses to requests superseded by a later edit", () => {
    render(renderCell());
    enterGrade("2");
    enterGrade("25");

    respond(requests[1], "25");
    respond(requests[0], "2");

    expect(props.updateTotal).toHaveBeenCalledTimes(1);
    expect(props.updateTotal).toHaveBeenCalledWith("1", 25, 25);
  });

  it("sends the updated grade to the server", () => {
    render(renderCell());
    enterGrade("5");

    expect($.ajax).toHaveBeenCalledWith(
      expect.objectContaining({
        url: Routes.update_grade_course_grade_entry_form_path(1, 1),
        type: "POST",
        data: {updated_grade: 5, student_id: 1, grade_entry_item_id: "1"},
      })
    );
  });

  it("sends an empty grade when the input is cleared", () => {
    render(renderCell());
    enterGrade("");

    expect($.ajax).toHaveBeenCalledWith(
      expect.objectContaining({data: expect.objectContaining({updated_grade: ""})})
    );
  });

  it("debounces requests while the grade is being typed", () => {
    render(renderCell());
    fireEvent.change(screen.getByRole("spinbutton"), {target: {value: "1"}});
    enterGrade("12");

    expect($.ajax).toHaveBeenCalledTimes(1);
    expect($.ajax).toHaveBeenCalledWith(
      expect.objectContaining({data: expect.objectContaining({updated_grade: 12})})
    );
  });

  it("does not send a negative grade for a non-bonus column", () => {
    render(renderCell());
    enterGrade("-1");

    expect($.ajax).not.toHaveBeenCalled();
    expect(screen.getByRole("spinbutton")).toHaveValue(-1);
  });

  it("sends a negative grade for a bonus column", () => {
    render(renderCell({bonus: true}));
    enterGrade("-1");

    expect($.ajax).toHaveBeenCalledWith(
      expect.objectContaining({data: expect.objectContaining({updated_grade: -1})})
    );
  });

  it("passes the new total to updateTotal", () => {
    render(renderCell());
    enterGrade("5");
    respond(requests[0], "12.5");

    expect(props.updateTotal).toHaveBeenCalledWith("1", 5, 12.5);
  });

  it("passes a not applicable total to updateTotal when the server returns no total", () => {
    render(renderCell());
    enterGrade("");
    respond(requests[0], "");

    expect(props.updateTotal).toHaveBeenCalledWith("1", "", I18n.t("not_applicable"));
  });

  it("renders an empty input when there is no grade", () => {
    render(renderCell({default_value: null}));

    expect(screen.getByRole("spinbutton")).toHaveValue(null);
  });

  it("only allows negative grades for bonus columns", () => {
    const {rerender} = render(renderCell());
    expect(screen.getByRole("spinbutton")).toHaveAttribute("min", "0");

    rerender(renderCell({bonus: true}));
    expect(screen.getByRole("spinbutton")).toHaveAttribute("min", "");
  });

  it("does not change the grade using the arrow keys", () => {
    render(renderCell());
    const input = screen.getByRole("spinbutton");

    expect(fireEvent.keyDown(input, {key: "ArrowUp"})).toBe(false);
    expect(fireEvent.keyDown(input, {key: "ArrowDown"})).toBe(false);
    expect(fireEvent.keyDown(input, {key: "Enter"})).toBe(true);
  });

  it("removes focus from the input when scrolling", () => {
    render(renderCell());
    const input = screen.getByRole("spinbutton");
    input.focus();

    fireEvent.wheel(input);

    expect(input).not.toHaveFocus();
  });
});

describe("MarksSpreadsheet", () => {
  const columns = [
    {accessor: "1", Header: "Q1 (10.0)", data: {bonus: false}},
    {accessor: "2", Header: "Q2 (5.0)", data: {bonus: true}},
  ];
  const students = [
    {
      _id: 1,
      user_name: "aaaa",
      first_name: "Alice",
      last_name: "Adams",
      section_id: 1,
      hidden: false,
      released_to_student: true,
      1: 7,
      2: 1,
      total_marks: 8,
    },
    {
      _id: 2,
      user_name: "bbbb",
      first_name: "Bob",
      last_name: "Brown",
      section_id: null,
      hidden: false,
      released_to_student: false,
      1: 4,
      total_marks: 4,
    },
    {
      _id: 3,
      user_name: "cccc",
      first_name: "Carol",
      last_name: "Clark",
      section_id: null,
      hidden: true,
      released_to_student: false,
      total_marks: I18n.t("not_applicable"),
    },
  ];
  const defaultProps = {
    course_id: 1,
    grade_entry_form_id: 1,
    show_total: false,
    max_mark: 15,
    show_sections: false,
    can_release: true,
  };

  const columnsPath = Routes.get_mark_columns_course_grade_entry_form_path(1, 1);
  const dataPath = Routes.populate_grades_table_course_grade_entry_form_path(1, 1);

  const renderSpreadsheet = async (props = {}) => {
    render(<MarksSpreadsheet {...defaultProps} {...props} />);
    await screen.findByText("aaaa");
    await waitFor(() => expect(gradeInputs(document)).toHaveLength(4));
  };

  const rowFor = user_name => screen.getByText(user_name).closest(".rt-tr");

  const gradeInputs = element => [...element.querySelectorAll("input[id^=grade_]")];

  beforeEach(() => {
    fetch.resetMocks();
    fetch.mockResponse(req => {
      if (req.url.startsWith(columnsPath)) {
        return Promise.resolve(JSON.stringify(columns));
      } else if (req.url.startsWith(dataPath)) {
        return Promise.resolve(JSON.stringify({data: students, sections: {1: "LEC0101"}}));
      }
      return Promise.reject(new Error(`Unexpected request: ${req.url}`));
    });
    jest.spyOn($, "ajax").mockImplementation(() => $.Deferred().resolve("").promise());
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("fetches the grade entry columns and student grades", async () => {
    await renderSpreadsheet();

    expect(fetch).toHaveBeenCalledWith(columnsPath, expect.anything());
    expect(fetch).toHaveBeenCalledWith(dataPath, expect.anything());
  });

  it("displays a header for each grade entry column", async () => {
    await renderSpreadsheet();

    expect(screen.getByText("Q1 (10.0)")).toBeInTheDocument();
    expect(screen.getByText("Q2 (5.0)")).toBeInTheDocument();
  });

  it("displays each active student with their grades", async () => {
    await renderSpreadsheet();

    const alice = within(rowFor("aaaa"));
    expect(alice.getByText("Alice")).toBeInTheDocument();
    expect(alice.getByText("Adams")).toBeInTheDocument();
    expect(gradeInputs(rowFor("aaaa")).map(input => input.value)).toEqual(["7", "1"]);

    expect(gradeInputs(rowFor("bbbb")).map(input => input.value)).toEqual(["4", ""]);
  });

  it("hides inactive students by default", async () => {
    await renderSpreadsheet();

    expect(screen.queryByText("cccc")).not.toBeInTheDocument();
  });

  it("displays inactive students when the display inactive checkbox is checked", async () => {
    await renderSpreadsheet();

    fireEvent.click(screen.getByLabelText(I18n.t("students.display_inactive")));

    expect(await screen.findByText("cccc")).toBeInTheDocument();
  });

  it("displays the released state of each student", async () => {
    await renderSpreadsheet();

    expect(
      within(rowFor("aaaa")).getByText(I18n.t("submissions.state.released"))
    ).toBeInTheDocument();
    expect(
      within(rowFor("bbbb")).queryByText(I18n.t("submissions.state.released"))
    ).not.toBeInTheDocument();
  });

  it("does not display the total column when show_total is false", async () => {
    await renderSpreadsheet();

    expect(
      screen.queryByText(`${I18n.t("activerecord.attributes.grade_entry_form.total")} (15)`)
    ).not.toBeInTheDocument();
  });

  describe("when show_total is true", () => {
    beforeEach(async () => {
      await renderSpreadsheet({show_total: true});
    });

    it("displays the total column", () => {
      expect(
        screen.getByText(`${I18n.t("activerecord.attributes.grade_entry_form.total")} (15)`)
      ).toBeInTheDocument();
      expect(within(rowFor("aaaa")).getByText("8")).toBeInTheDocument();
    });

    it("updates the total after a grade is saved", async () => {
      $.ajax.mockImplementation(() => $.Deferred().resolve("10").promise());

      const input = gradeInputs(rowFor("bbbb"))[1];
      fireEvent.change(input, {target: {value: "6"}});

      expect(await within(rowFor("bbbb")).findByText("10")).toBeInTheDocument();
      expect(input).toHaveValue(6);
    });
  });

  it("does not display the section column when show_sections is false", async () => {
    await renderSpreadsheet();

    expect(
      screen.queryByText(I18n.t("activerecord.models.section", {count: 1}))
    ).not.toBeInTheDocument();
  });

  it("displays the section of each student when show_sections is true", async () => {
    await renderSpreadsheet({show_sections: true});

    expect(screen.getByText(I18n.t("activerecord.models.section", {count: 1}))).toBeInTheDocument();
    expect(within(rowFor("aaaa")).getByText("LEC0101")).toBeInTheDocument();
  });

  describe("filtering", () => {
    const userNameFilter = () => document.querySelector(".rt-thead.-filters input[type=text]");

    it("filters students by user name", async () => {
      await renderSpreadsheet();

      fireEvent.change(userNameFilter(), {target: {value: "bb"}});

      await waitFor(() => expect(screen.queryByText("aaaa")).not.toBeInTheDocument());
      expect(screen.getByText("bbbb")).toBeInTheDocument();
    });

    it("keeps other filters when displaying inactive students", async () => {
      await renderSpreadsheet();
      fireEvent.change(userNameFilter(), {target: {value: "cc"}});
      await waitFor(() => expect(screen.queryByText("aaaa")).not.toBeInTheDocument());

      fireEvent.click(screen.getByLabelText(I18n.t("students.display_inactive")));

      expect(await screen.findByText("cccc")).toBeInTheDocument();
      expect(screen.queryByText("aaaa")).not.toBeInTheDocument();
      expect(screen.queryByText("bbbb")).not.toBeInTheDocument();
    });

    it("filters students by section", async () => {
      await renderSpreadsheet({show_sections: true});
      const sectionFilter = screen.getByRole("combobox", {
        name: I18n.t("filter_by", {name: I18n.t("activerecord.models.section", {count: 1})}),
      });

      fireEvent.change(sectionFilter, {target: {value: "LEC0101"}});
      await waitFor(() => expect(screen.queryByText("bbbb")).not.toBeInTheDocument());
      expect(screen.getByText("aaaa")).toBeInTheDocument();

      fireEvent.change(sectionFilter, {target: {value: "all"}});
      expect(await screen.findByText("bbbb")).toBeInTheDocument();
    });
  });

  it("sorts students by total", async () => {
    await renderSpreadsheet({show_total: true});
    fireEvent.click(screen.getByLabelText(I18n.t("students.display_inactive")));
    await screen.findByText("cccc");
    const userNames = () =>
      [...document.querySelectorAll(".rt-tbody .rt-tr")]
        .map(row => ["aaaa", "bbbb", "cccc"].find(name => row.textContent.includes(name)))
        .filter(Boolean);
    const totalHeader = screen.getByText(
      `${I18n.t("activerecord.attributes.grade_entry_form.total")} (15)`
    );

    fireEvent.click(totalHeader);
    await waitFor(() => expect(userNames()).toEqual(["aaaa", "bbbb", "cccc"]));

    fireEvent.click(totalHeader);
    await waitFor(() => expect(userNames()).toEqual(["cccc", "bbbb", "aaaa"]));
  });

  it("does not display the release buttons when can_release is false", async () => {
    await renderSpreadsheet({can_release: false});

    expect(screen.queryByText(I18n.t("submissions.release_marks"))).not.toBeInTheDocument();
    expect(screen.queryByText(I18n.t("submissions.unrelease_marks"))).not.toBeInTheDocument();
  });

  it.each([
    ["release_marks", true],
    ["unrelease_marks", false],
  ])(
    "sends a request when the %s button is clicked and refreshes the data",
    async (key, released) => {
      await renderSpreadsheet();
      fetch.mockClear();

      fireEvent.click(screen.getByText(I18n.t(`submissions.${key}`)));

      expect($.ajax).toHaveBeenCalledWith(
        expect.objectContaining({
          method: "POST",
          url: Routes.update_grade_entry_students_course_grade_entry_form_path(1, 1),
          data: {release_results: released, filter: "none", students: []},
        })
      );
      await waitFor(() => expect(fetch).toHaveBeenCalledWith(dataPath, expect.anything()));
    }
  );
});
