import {render} from "@testing-library/react";
import {ResultContext} from "../Result/result_context";

export const DEFAULT_RESULT_CONTEXT_VALUE = {
  result_id: 1,
  submission_id: 1,
  assignment_id: 1,
  grouping_id: 1,
  course_id: 1,
  role: "user",
  is_reviewer: true,
};

export function renderInResultContext(ui, contextValue = {}, renderOptions = {}) {
  const mergedContextValue = {
    ...DEFAULT_RESULT_CONTEXT_VALUE,
    ...contextValue,
  };

  return render(
    <ResultContext.Provider value={mergedContextValue}>{ui}</ResultContext.Provider>,
    renderOptions
  );
}
