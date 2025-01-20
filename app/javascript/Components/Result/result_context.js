import React from "react";

// This needs to be in its own file to avoid circular dependency.
export const ResultContext = React.createContext({
  assignment_id: null,
  submission_id: null,
  result_id: null,
  grouping_id: null,
  course_id: null,
  role: null,
  is_reviewer: null,
});
