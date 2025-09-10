import * as React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import DownloadTestResultsModal from "../Modals/download_test_results_modal";
import {beforeEach, describe, expect, it} from "@jest/globals";

describe("DownloadTestResultsModal", () => {
  let props;

  beforeEach(() => {
    props = {
      isOpen: true,
      onRequestClose: jest.fn(),
      course_id: 1,
      assignment_id: 2,
    };
  });

  describe("Initial state", () => {
    it("should render the modal with correct title", () => {
      render(<DownloadTestResultsModal {...props} />);
      expect(
        screen.getByText(
          I18n.t("download_the", {item: I18n.t("activerecord.models.test_result.other")})
        )
      ).toBeInTheDocument();
    });

    it("should render all radio button options", () => {
      render(<DownloadTestResultsModal {...props} />);

      expect(screen.getByLabelText(I18n.t("anyone"))).toBeInTheDocument();
      expect(screen.getByLabelText(I18n.t("activerecord.models.student.one"))).toBeInTheDocument();
      expect(
        screen.getByLabelText(I18n.t("activerecord.models.instructor.one"))
      ).toBeInTheDocument();

      expect(screen.getByLabelText(I18n.t("all"))).toBeInTheDocument();
      expect(screen.getByLabelText(I18n.t("latest"))).toBeInTheDocument();

      expect(screen.getByLabelText(I18n.t("format.json"))).toBeInTheDocument();
      expect(screen.getByLabelText(I18n.t("format.csv"))).toBeInTheDocument();
    });
  });

  describe("Run by radio selection", () => {
    it("should update state when Student is selected", () => {
      render(<DownloadTestResultsModal {...props} />);

      const studentRadio = screen.getByLabelText(I18n.t("activerecord.models.student.one"));
      fireEvent.click(studentRadio);

      expect(studentRadio).toBeChecked();
      expect(screen.getByLabelText(I18n.t("anyone"))).not.toBeChecked();
      expect(screen.getByLabelText(I18n.t("activerecord.models.instructor.one"))).not.toBeChecked();
    });

    it("should update state when Instructor is selected", () => {
      render(<DownloadTestResultsModal {...props} />);

      const instructorRadio = screen.getByLabelText(I18n.t("activerecord.models.instructor.one"));
      fireEvent.click(instructorRadio);

      expect(instructorRadio).toBeChecked();
      expect(screen.getByLabelText(I18n.t("anyone"))).not.toBeChecked();
      expect(screen.getByLabelText(I18n.t("activerecord.models.student.one"))).not.toBeChecked();
    });

    it("should allow switching back to Anyone", () => {
      render(<DownloadTestResultsModal {...props} />);

      const studentRadio = screen.getByLabelText(I18n.t("activerecord.models.student.one"));
      fireEvent.click(studentRadio);
      expect(studentRadio).toBeChecked();

      const anyoneRadio = screen.getByLabelText(I18n.t("anyone"));
      fireEvent.click(anyoneRadio);
      expect(anyoneRadio).toBeChecked();
      expect(studentRadio).not.toBeChecked();
    });
  });

  describe("Type radio selection", () => {
    it("should update state when Latest is selected", () => {
      render(<DownloadTestResultsModal {...props} />);

      const latestRadio = screen.getByLabelText(I18n.t("latest"));
      fireEvent.click(latestRadio);

      expect(latestRadio).toBeChecked();
      expect(screen.getByLabelText(I18n.t("all"))).not.toBeChecked();
    });

    it("should switch back to All when selected", () => {
      render(<DownloadTestResultsModal {...props} />);

      const latestRadio = screen.getByLabelText(I18n.t("latest"));
      fireEvent.click(latestRadio);
      expect(latestRadio).toBeChecked();

      const allRadio = screen.getByLabelText(I18n.t("all"));
      fireEvent.click(allRadio);
      expect(allRadio).toBeChecked();
      expect(latestRadio).not.toBeChecked();
    });
  });

  describe("format radio selection", () => {
    it("should update state when CSV is selected", () => {
      render(<DownloadTestResultsModal {...props} />);

      const csvRadio = screen.getByLabelText(I18n.t("format.csv"));
      fireEvent.click(csvRadio);

      expect(csvRadio).toBeChecked();
      expect(screen.getByLabelText(I18n.t("format.json"))).not.toBeChecked();
    });

    it("should switch back to JSON when selected", () => {
      render(<DownloadTestResultsModal {...props} />);

      const csvRadio = screen.getByLabelText(I18n.t("format.csv"));
      fireEvent.click(csvRadio);
      expect(csvRadio).toBeChecked();

      const jsonRadio = screen.getByLabelText(I18n.t("format.json"));
      fireEvent.click(jsonRadio);
      expect(jsonRadio).toBeChecked();
      expect(csvRadio).not.toBeChecked();
    });

    it("should enable CSV when Latest type is selected", () => {
      render(<DownloadTestResultsModal {...props} />);

      const latestRadio = screen.getByLabelText(I18n.t("latest"));
      fireEvent.click(latestRadio);

      const csvRadio = screen.getByLabelText(I18n.t("format.csv"));
      expect(csvRadio).not.toBeDisabled();
    });
  });

  describe("Modal interaction", () => {
    it("should call onRequestClose when Cancel is clicked", () => {
      render(<DownloadTestResultsModal {...props} />);

      const cancelButton = screen.getByDisplayValue(I18n.t("cancel"));
      fireEvent.click(cancelButton);

      expect(props.onRequestClose).toHaveBeenCalled();
    });

    it("should call onRequestClose when Download is clicked", () => {
      render(<DownloadTestResultsModal {...props} />);

      const downloadButton = screen.getByText(I18n.t("download"));
      fireEvent.click(downloadButton);

      expect(props.onRequestClose).toHaveBeenCalled();
    });

    it("should handle multiple radio selections correctly", () => {
      render(<DownloadTestResultsModal {...props} />);

      fireEvent.click(screen.getByLabelText(I18n.t("activerecord.models.student.one")));
      fireEvent.click(screen.getByLabelText(I18n.t("latest")));
      fireEvent.click(screen.getByLabelText(I18n.t("format.csv")));

      expect(screen.getByLabelText(I18n.t("activerecord.models.student.one"))).toBeChecked();
      expect(screen.getByLabelText(I18n.t("latest"))).toBeChecked();
      expect(screen.getByLabelText(I18n.t("format.csv"))).toBeChecked();

      expect(screen.getByLabelText(I18n.t("anyone"))).not.toBeChecked();
      expect(screen.getByLabelText(I18n.t("activerecord.models.instructor.one"))).not.toBeChecked();
      expect(screen.getByLabelText(I18n.t("all"))).not.toBeChecked();
      expect(screen.getByLabelText(I18n.t("format.json"))).not.toBeChecked();
    });

    it("should revert to JSON when switching from Latest to All", () => {
      render(<DownloadTestResultsModal {...props} />);

      fireEvent.click(screen.getByLabelText(I18n.t("latest")));
      fireEvent.click(screen.getByLabelText(I18n.t("format.csv")));

      expect(screen.getByLabelText(I18n.t("format.csv"))).toBeChecked();

      fireEvent.click(screen.getByLabelText(I18n.t("all")));

      expect(screen.getByLabelText(I18n.t("format.json"))).toBeChecked();
      expect(screen.getByLabelText(I18n.t("format.csv"))).toBeDisabled();
    });
  });
});
