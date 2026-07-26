import {getInitialFilterData, restoreFilterData} from "../Result/filter_data";

describe("Result filter data", () => {
  const filterStorageKey = "1_2_filterData";

  beforeEach(() => {
    localStorage.clear();
  });

  it("uses role-specific submission scope defaults", () => {
    expect(getInitialFilterData("Instructor").assignedGradersOnly).toBe(false);
    expect(getInitialFilterData("Ta").assignedGradersOnly).toBe(true);
  });

  it("defaults instructors to all submissions", () => {
    const filterData = restoreFilterData("Instructor", filterStorageKey);

    expect(filterData).toEqual(getInitialFilterData("Instructor"));
  });

  it("fills in missing saved values with the role defaults", () => {
    localStorage.setItem(filterStorageKey, JSON.stringify({annotationText: "needle"}));

    const filterData = restoreFilterData("Instructor", filterStorageKey);

    expect(filterData).toEqual({
      ...getInitialFilterData("Instructor"),
      annotationText: "needle",
    });
    expect(filterData.assignedGradersOnly).toBe(false);
  });

  it("restores an instructor's saved scope", () => {
    localStorage.setItem(
      filterStorageKey,
      JSON.stringify({...getInitialFilterData("Instructor"), assignedGradersOnly: true})
    );

    const filterData = restoreFilterData("Instructor", filterStorageKey);

    expect(filterData.assignedGradersOnly).toBe(true);
  });

  it("restores a TA's saved scope", () => {
    localStorage.setItem(
      filterStorageKey,
      JSON.stringify({...getInitialFilterData("Ta"), assignedGradersOnly: false})
    );

    const filterData = restoreFilterData("Ta", filterStorageKey);

    expect(filterData.assignedGradersOnly).toBe(false);
  });

  it("uses the role default when the stored filter is invalid", () => {
    localStorage.setItem(filterStorageKey, "{invalid");

    const filterData = restoreFilterData("Ta", filterStorageKey);

    expect(filterData).toEqual(getInitialFilterData("Ta"));
  });
});
