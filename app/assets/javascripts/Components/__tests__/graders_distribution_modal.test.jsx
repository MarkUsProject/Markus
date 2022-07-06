import {shallow} from "enzyme";

import {GraderDistributionModal} from "../Modals/graders_distribution_modal";

describe("GraderDistributionModal", () => {
  let wrapper, props;
  const getWrapper = props => {
    return shallow(<GraderDistributionModal {...props} />);
  };
  beforeEach(() => {
    props = {
      graders: [
        {user_name: "1", _id: 1},
        {user_name: "2", _id: 2},
      ],
      isOpen: true,
      onSubmit: jest.fn().mockImplementation(() => (props.isOpen = false)),
    };
  });

  it("should display as many rows as there are graders", () => {
    wrapper = getWrapper(props);

    expect(wrapper.find(".modal-inline-label").length).toBe(2);
  });

  it("should close on submit", () => {
    wrapper = getWrapper(props);

    wrapper.find("#grader-form-random").simulate("submit", {preventDefault: jest.fn()});

    expect(props.onSubmit).toHaveBeenCalled();
    expect(props.isOpen).toBeFalsy();
  });

  it("should call setWeighting with value of 1 on build", () => {
    const fakeEvent = {preventDefault: jest.fn()};
    wrapper = getWrapper(props);

    wrapper.find("#grader-form-random").trigger("submit", fakeEvent);
    expect(props.onSubmit).toHaveBeenCalledWith({
      1: 1,
      2: 1,
    });
  });

  it("should call setWeighting with correct ID and number upon an event", () => {
    const fakeEvent = {preventDefault: jest.fn()};
    wrapper = getWrapper(props);

    wrapper.find(`#input-1`).simulate("change", {target: {value: "2"}});
    wrapper.find("#grader-form-random").trigger("submit", fakeEvent);
    expect(props.onSubmit).toHaveBeenCalledWith({
      1: 2,
      2: 1,
    });
  });
});
