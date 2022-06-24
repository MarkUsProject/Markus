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
      weightings: {},
    };
  });

  it("should display as many rows as there are graders", () => {
    wrapper = getWrapper(props);

    expect(wrapper.find(".modal-inline-label").length).toBe(2);
  });

  it("should default weightings to 1 if none are received", () => {
    wrapper = getWrapper(props);

    expect(props.weightings).toEqual({
      1: 1,
      2: 1,
    });
  });

  it("should update weightings on an input change", () => {
    wrapper = getWrapper(props);

    wrapper.find(`#input-1`).simulate("change", {target: {value: "2"}});

    expect(props.weightings).toEqual({
      1: 2,
      2: 1,
    });
  });

  it("should keep any given weightings", () => {
    props.weightings["1"] = 100;
    wrapper = getWrapper(props);

    expect(props.weightings).toEqual({
      1: 100,
      2: 1,
    });
  });

  it("should close on submit", () => {
    wrapper = getWrapper(props);

    wrapper.find("#grader-form-random").simulate("submit", {preventDefault: jest.fn()});

    expect(props.onSubmit).toHaveBeenCalled();
    expect(props.isOpen).toBeFalsy();
  });
});
