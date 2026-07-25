export const getInitialFilterData = role => ({
  ascending: true,
  orderBy: "group_name",
  assignedGradersOnly: role === "Ta",
  annotationText: "",
  tas: [],
  tags: [],
  section: "",
  markingState: "",
  totalMarkRange: {
    min: "",
    max: "",
  },
  totalExtraMarkRange: {
    min: "",
    max: "",
  },
  criteria: {},
});

export const getFilterStorageKey = (userId, assignmentId) => `${userId}_${assignmentId}_filterData`;

export const restoreFilterData = (role, filterStorageKey) => {
  const submissionScopeVersionKey = `${filterStorageKey}_submissionScopeVersion`;
  const initializeInstructorSubmissionScope =
    role === "Instructor" && localStorage.getItem(submissionScopeVersionKey) !== "1";
  const storedFilter = localStorage.getItem(filterStorageKey);
  let filterData;
  try {
    filterData = JSON.parse(storedFilter);
  } catch (e) {
    filterData = null;
  }
  const hasValidStoredFilter = Boolean(filterData);

  if (hasValidStoredFilter) {
    if (initializeInstructorSubmissionScope) {
      filterData = {...filterData, assignedGradersOnly: false};
    }
  } else {
    filterData = getInitialFilterData(role);
  }

  if (!hasValidStoredFilter || initializeInstructorSubmissionScope) {
    localStorage.setItem(filterStorageKey, JSON.stringify(filterData));
  }
  if (initializeInstructorSubmissionScope) {
    localStorage.setItem(submissionScopeVersionKey, "1");
  }

  return filterData;
};
