import {render, screen, fireEvent, waitFor} from "@testing-library/react";
import CollectSubmissionsModal from "../Modals/collect_submissions_modal";
import Modal from "react-modal";

describe("CollectSubmissionsModal", () => {
  let props;

  beforeEach(() => {
    props = {
      isOpen: true,
      isScannedExam: false,
      onRequestClose: jest.fn(),
      onSubmit: jest.fn(),
    };

    // Set the app element for React Modal
    Modal.setAppElement("body");
    render(<CollectSubmissionsModal {...props} />);
  });

  it("should display the option to recollect old submissions unchecked by default", () => {
    const lblRecollectExistingSubmissions = screen.getByTestId(
      "lbl_recollect_existing_submissions"
    );
    const chkRecollectExistingSubmissions = screen.getByTestId(
      "chk_recollect_existing_submissions"
    );

    expect(lblRecollectExistingSubmissions).toBeInTheDocument();
    expect(chkRecollectExistingSubmissions).toBeInTheDocument();
    expect(chkRecollectExistingSubmissions.checked).toBe(false);
  });

  describe("when the option to recollect checkbox is checked", () => {
    beforeEach(() => {
      fireEvent.click(screen.getByTestId("chk_recollect_existing_submissions"));
    });

    it("should display the option to retain existing grading checked by default", () => {
      const lblRetainExistingGrading = screen.getByTestId("lbl_retain_existing_grading");
      const chkRetainExistingGrading = screen.getByTestId("chk_retain_existing_grading");

      expect(lblRetainExistingGrading).toBeInTheDocument();
      expect(chkRetainExistingGrading).toBeInTheDocument();
      expect(chkRetainExistingGrading.checked).toBe(true);
    });

    it("should display a warning when the retain existing grading option is unchecked", () => {
      const chkRetainExistingGrading = screen.getByTestId("chk_retain_existing_grading");

      fireEvent.click(chkRetainExistingGrading);

      const divGradingDataWillBeLost = screen.getByTestId("div_grading_data_will_be_lost");
      const lblRetainExistingGrading = screen.queryByTestId("lbl_retain_existing_grading");

      expect(chkRetainExistingGrading.checked).toBe(false);
      expect(divGradingDataWillBeLost).toBeInTheDocument();
      expect(lblRetainExistingGrading).toBeInTheDocument();
    });

    it("should call onSubmit with the correct parameters when the form is submitted", async () => {
      const btnCollectSubmissions = screen.getByTestId("btn_collect_submissions");

      fireEvent.click(btnCollectSubmissions);

      await waitFor(() => {
        expect(props.onSubmit).toHaveBeenCalledTimes(1);
        expect(props.onSubmit).toHaveBeenCalledWith(true, false, true, true);
      });
    });
  });
});
