import {shallow} from "enzyme";

import {GraderDistributionModal} from "../Modals/graders_distribution_modal";

const createExampleForm = () => {
  const form1 = new FormData();
  form1.append("2", "1");
  form1.append("1", "1");
  return form1;
};

describe("GraderDistributionModal", () => {
  let wrapper, props;
  const getWrapper = props => {
    return shallow(<GraderDistributionModal {...props} />);
  };
  const fakeEvent = {preventDefault: jest.fn()};
  let mockRef;
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
    jest.spyOn(window, "FormData").mockImplementationOnce(() => form1);
  });

  it("should display as many rows as there are graders", () => {
    wrapper = getWrapper(props);

    expect(wrapper.find(".modal-inline-label").length).toBe(2);
  });

  it("should close on submit", () => {
    wrapper = getWrapper(props);

    wrapper.find("#grader-form-random").simulate("submit", fakeEvent);

    expect(props.onSubmit).toHaveBeenCalled();
    expect(props.isOpen).toBeFalsy();
  });

  it("should call setWeighting with value of 1 on build", () => {
    wrapper = getWrapper(props);

    wrapper.find("#grader-form-random").simulate("submit", fakeEvent);
    expect(props.onSubmit).toHaveBeenCalledWith({
      1: "1",
      2: "1",
    });
  });
});
