import React, {useState, useRef, useEffect, useCallback} from "react";
import {Grid} from "react-loader-spinner";

import {ImageViewer} from "./image_viewer";
import {TextViewer} from "./text_viewer";
import {PDFViewer} from "./pdf_viewer";
import {HTMLViewer} from "./html_viewer";
import {BinaryViewer} from "./binary_viewer";
import {URLViewer} from "./url_viewer";

export const FileViewer = React.memo(function FileViewer(props) {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null);

  useEffect(() => {
    setLoading(true);
    setErrorMessage(null);
  }, [props.selectedFile, props.selectedFileURL, props.selectedFileType]);

  const commonProps = {
    submission_file_id: props.selectedFile,
    annotations: props.annotations ?? [],
    released_to_students: props.released_to_students,
    resultView: !!props.result_id,
    course_id: props.course_id,
    key: `${props.selectedFileType}-viewer`,
    url: props.selectedFileURL,
    setLoadingCallback: setLoading,
    setErrorMessageCallback: setErrorMessage,
  };

  let viewer;
  if (props.selectedFileType === "image") {
    viewer = <ImageViewer mime_type={props.mime_type} {...commonProps} />;
  } else if (props.selectedFileType === "pdf") {
    viewer = <PDFViewer annotationFocus={props.annotationFocus} {...commonProps} />;
  } else if (
    props.selectedFileType === "jupyter-notebook" ||
    (props.selectedFileType === "rmarkdown" && props.rmd_convert_enabled)
  ) {
    viewer = <HTMLViewer annotationFocus={props.annotationFocus} {...commonProps} />;
  } else if (props.selectedFileType === "binary") {
    viewer = <BinaryViewer {...commonProps} />;
  } else if (props.selectedFileType === "markusurl") {
    viewer = <URLViewer {...commonProps} />;
  } else if (props.selectedFileType !== "") {
    viewer = (
      <TextViewer
        type={props.selectedFileType === "rmarkdown" ? "markdown" : props.selectedFileType}
        focusLine={props.focusLine}
        {...commonProps}
      />
    );
  } else {
    viewer = "";
  }

  const outerDivStyle = {
    display: loading || errorMessage ? "none" : "block",
    height: "100%",
  };

  return (
    <React.Fragment>
      <div style={outerDivStyle}>{viewer}</div>
      {errorMessage && <p>{errorMessage}</p>}
      {loading && !errorMessage && (
        <div className="loading-spinner">
          <Grid
            visible={true}
            height="25"
            width="25"
            color="#31649B"
            aria-label="grid-loading"
            radius="12.5"
            wrapperStyle={{}}
            wrapperClass="grid-wrapper"
          />
        </div>
      )}
    </React.Fragment>
  );
});
