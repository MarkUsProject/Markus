import {Result} from "../Result/result";

describe("Result submission scope restoration", () => {
  const props = {
    assignment_id: 1,
    course_id: 1,
    grouping_id: 1,
    result_id: 1,
    role: "Instructor",
    submission_id: 1,
    user_id: 1,
  };

  let result;

  beforeEach(() => {
    localStorage.clear();
    result = new Result(props);
    result.setState = jest.fn((updates, callback) => {
      result.state = {...result.state, ...updates};
      callback?.();
    });
  });

  it("defaults instructors to all submissions", () => {
    result.refreshFilterData();

    expect(result.state.filterData.assignedGradersOnly).toBe(false);
  });

  it("migrates the previously hidden instructor scope to all submissions", () => {
    const filterStorageKey = result.filterStorageKey();
    localStorage.setItem(
      filterStorageKey,
      JSON.stringify({...result.initialFilterModalState, assignedGradersOnly: true})
    );

    result.refreshFilterData();

    expect(result.state.filterData.assignedGradersOnly).toBe(false);
    expect(localStorage.getItem(`${filterStorageKey}_submissionScopeVersion`)).toBe("1");
  });

  it("restores an instructor's saved scope before running the completion callback", () => {
    const filterStorageKey = result.filterStorageKey();
    localStorage.setItem(
      filterStorageKey,
      JSON.stringify({...result.initialFilterModalState, assignedGradersOnly: true})
    );
    localStorage.setItem(`${filterStorageKey}_submissionScopeVersion`, "1");
    const onComplete = jest.fn(() => {
      expect(result.state.filterData.assignedGradersOnly).toBe(true);
    });

    result.refreshFilterData(onComplete);

    expect(onComplete).toHaveBeenCalled();
  });
});
