import {act, render, screen, waitFor} from "@testing-library/react";

/**
 * Lets pending promises (such as mocked fetch requests) resolve, and applies the
 * state updates they cause inside act(...).
 */
export function flushPromises() {
  return act(() => new Promise(resolve => setTimeout(resolve, 0)));
}

/**
 * Renders ui, then waits for the data that its components fetch when they mount.
 * Use this for components that do not show a loading indicator to wait for.
 */
export async function renderAndLoad(ui, options) {
  const result = render(ui, options);
  await flushPromises();
  return result;
}

/**
 * Waits for a Table to finish loading, i.e. for its loading spinner to disappear.
 */
export function waitForTableLoad() {
  return waitFor(() => expect(screen.queryByLabelText(I18n.t("working"))).not.toBeInTheDocument());
}
