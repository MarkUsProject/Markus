import FileManager from "../markus_file_manager";

import {render, screen} from "@testing-library/react";

describe("For the submissions managed by the FileManager component", () => {
  const files_sample = [
    {
      id: 136680,
      url: "test.url",
      filename: '<img src="" /><a href=""> HelloWorld.java</a>',
      raw_name: "HelloWorld.java",
      last_revised_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
      last_modified_revision: "58ca2e15254aa63c4d41cb5db7dfc398b6bda3fb",
      revision_by: "c5anthei",
      submitted_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
      type: "java",
      key: "HelloWorld.java",
      modified: 1652577324,
      relativeKey: "HelloWorld.java",
    },
    {
      id: 136700,
      url: "test2.url",
      filename: '<img src="" /><a href=""> deferred-process.jpg</a>',
      raw_name: "deferred-process.jpg",
      last_revised_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
      last_modified_revision: "58ca2e15254aa63c4d41cb5db7dfc398b6bda3fb",
      revision_by: "c5anthei",
      submitted_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
      type: "image",
      key: "deferred-process.jpg",
      modified: 1652577324,
      relativeKey: "deferred-process.jpg",
    },
  ];

  beforeEach(() => {
    render(<FileManager files={files_sample} />);
  });

  // We shouldn't test whether clicking on an <a> element with download enabled will trigger the download, as that is
  // internal HTML built-in.
  // Instead, we can test if for each given file, an <a> element is generated with the correct download and href props.
  it(
    "each file is rendered with a hyperlink/tag element with href being the file url " +
      "and download being the filename",
    () => {
      files_sample.forEach(file => {
        const link = screen.getByRole("link", {
          name: I18n.t("download_the", {item: file.raw_name}),
        });
        expect(link).toHaveAttribute("href", file.url);
        expect(link).toHaveAttribute("download", file.raw_name);
      });
    }
  );
});
