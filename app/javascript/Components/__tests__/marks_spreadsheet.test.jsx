/***
 * Tests for GradeEntryCell Component
 */

import {GradeEntryCell} from "../marks_spreadsheet";
import {render, screen, fireEvent, act} from "@testing-library/react";
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
});
