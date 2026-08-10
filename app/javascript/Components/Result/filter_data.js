/**
 * Return the default submission filters for the given role.
 *
 * @param {string} role The user's course role.
 * @returns {object} The default filter data.
 */
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

/**
 * Restore saved submission filters, filling in missing values with the current defaults.
 *
 * @param {string} role The user's course role.
 * @param {string} filterStorageKey The local storage key containing the saved filters.
 * @returns {object} The restored filter data.
 */
export const restoreFilterData = (role, filterStorageKey) => {
  const storedFilter = localStorage.getItem(filterStorageKey);
  let filterData = {};
  try {
    filterData = JSON.parse(storedFilter) || {};
  } catch (e) {
    // Use the current defaults if the saved filter data is invalid.
  }

  return $.extend(true, {}, getInitialFilterData(role), filterData);
};
