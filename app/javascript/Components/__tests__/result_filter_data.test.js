import {getFilterStorageKey, getInitialFilterData, restoreFilterData} from "../Result/filter_data";

describe("Result filter data", () => {
  const filterStorageKey = getFilterStorageKey(1, 2);
  const submissionScopeVersionKey = `${filterStorageKey}_submissionScopeVersion`;

  beforeEach(() => {
    localStorage.clear();
  });

  it("uses role-specific submission scope defaults", () => {
    expect(getInitialFilterData("Instructor").assignedGradersOnly).toBe(false);
    expect(getInitialFilterData("Ta").assignedGradersOnly).toBe(true);
  });

  it("uses a user- and assignment-specific storage key", () => {
    expect(filterStorageKey).toBe("1_2_filterData");
  });

  it("defaults instructors to all submissions", () => {
    const filterData = restoreFilterData("Instructor", filterStorageKey);

    expect(filterData.assignedGradersOnly).toBe(false);
    expect(JSON.parse(localStorage.getItem(filterStorageKey))).toEqual(filterData);
    expect(localStorage.getItem(submissionScopeVersionKey)).toBe("1");
  });

  it("migrates the previously hidden instructor scope to all submissions", () => {
    localStorage.setItem(
      filterStorageKey,
      JSON.stringify({...getInitialFilterData("Instructor"), assignedGradersOnly: true})
    );

    const filterData = restoreFilterData("Instructor", filterStorageKey);

    expect(filterData.assignedGradersOnly).toBe(false);
    expect(localStorage.getItem(submissionScopeVersionKey)).toBe("1");
  });

  it("restores an instructor's saved scope after migration", () => {
    localStorage.setItem(
      filterStorageKey,
      JSON.stringify({...getInitialFilterData("Instructor"), assignedGradersOnly: true})
    );
    localStorage.setItem(submissionScopeVersionKey, "1");

    const filterData = restoreFilterData("Instructor", filterStorageKey);

    expect(filterData.assignedGradersOnly).toBe(true);
  });

  it("restores a TA's saved scope without applying the instructor migration", () => {
    localStorage.setItem(
      filterStorageKey,
      JSON.stringify({...getInitialFilterData("Ta"), assignedGradersOnly: false})
    );

    const filterData = restoreFilterData("Ta", filterStorageKey);

    expect(filterData.assignedGradersOnly).toBe(false);
    expect(localStorage.getItem(submissionScopeVersionKey)).toBeNull();
  });

  it("uses the role default when the stored filter is invalid", () => {
    localStorage.setItem(filterStorageKey, "{invalid");

    const filterData = restoreFilterData("Ta", filterStorageKey);

    expect(filterData).toEqual(getInitialFilterData("Ta"));
    expect(JSON.parse(localStorage.getItem(filterStorageKey))).toEqual(filterData);
  });
});
