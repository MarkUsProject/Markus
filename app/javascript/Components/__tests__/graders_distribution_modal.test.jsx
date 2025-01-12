import {render, screen} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import {GraderDistributionModal} from "../Modals/graders_distribution_modal";

const createExampleForm = () => {
  const form1 = new FormData();
  form1.append("2", "1");
  form1.append("1", "1");
  return form1;
};

describe("GraderDistributionModal", () => {
  let props;
  const form1 = createExampleForm();
  beforeEach(() => {
    props = {
      graders: [
        {user_name: "1", _id: 1},
        {user_name: "2", _id: 2},
      ],
      isOpen: true,
      onSubmit: jest.fn().mockImplementation(() => (props.isOpen = false)),
    };
    global.MARKUS_VERSION = "master";
    jest.spyOn(window, "FormData").mockImplementationOnce(() => form1);
  });

  it("should display as many rows as there are graders", () => {
    render(<GraderDistributionModal {...props} />);
    for (let grader of props.graders) {
      expect(screen.getByRole("spinbutton", {name: grader.user_name, hidden: true})).toBeTruthy();
    }
  });

  it("should close on submit", async () => {
    render(<GraderDistributionModal {...props} />);
    let submit = screen.getByRole("button", {
      name: I18n.t("graders.actions.randomly_assign_graders"),
      hidden: true,
    });
    await userEvent.click(submit);

    expect(props.onSubmit).toHaveBeenCalled();
    expect(props.isOpen).toBeFalsy();
  });

  it("should call setWeighting with value of 1 on build", async () => {
    render(<GraderDistributionModal {...props} />);
    let submit = screen.getByRole("button", {
      name: I18n.t("graders.actions.randomly_assign_graders"),
      hidden: true,
    });
    await userEvent.click(submit);

    expect(props.onSubmit).toHaveBeenCalledWith({
      1: "1",
      2: "1",
    });
  });
});
