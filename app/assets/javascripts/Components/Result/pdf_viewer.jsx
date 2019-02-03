import React from 'react';
import {render} from 'react-dom';


export class PDFViewer extends React.Component {
  constructor() {
    super();
  }

  componentDidMount() {
    if (this.props.url) {
      this.loadPDFFile();
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.url && this.props.url !== prevProps.url) {
      this.loadPDFFile();
    }
  }

  loadPDFFile = () => {
    if (typeof(PDFView) === 'undefined') {
      $.getScript(PDFJS_PATH).done(() => {
        PDFJS.workerSrc = PDFJS_WORKER_PATH;

        PDFView.onLoadComplete = () => {
          window.source_code_ready_for_pdf(PDFView, 'viewer');
          annotationPanel.annotationTable.current.display_annotations(this.props.submission_file_id);
        };
        webViewerLoad(this.props.url);
      });
    } else {
      PDFView.onLoadComplete = () => {
        window.source_code_ready_for_pdf(PDFView, 'viewer');
        annotationPanel.annotationTable.current.display_annotations(this.props.submission_file_id);
      };
      webViewerLoad(this.props.url);
    }
  }


  render() {
    return (
      <div id="outerContainer" className="loadingInProgress flex-col">
        <div id="mainContainer">
          <div className="toolbar">
            <div id="toolbarContainer">
              <div id="toolbarViewer">
                <div id="toolbarViewerLeft">
                  <div className="splitToolbarButton">
                    <button className="toolbarButton pageUp" title="Previous Page" id="previous" tabIndex="13" data-l10n-id="previous">
                      <span data-l10n-id="previous_label">Previous</span>
                    </button>
                    <div className="splitToolbarButtonSeparator" />
                    <button className="toolbarButton pageDown" title="Next Page" id="next" tabIndex="14" data-l10n-id="next">
                      <span data-l10n-id="next_label">Next</span>
                    </button>
                  </div>
                  <button className="toolbarButton rotateMarkus" title="Rotate" onClick={() => {rotate(); return false;}}/>

                  <label id="pageNumberLabel" className="toolbarLabel" htmlFor="pageNumber" data-l10n-id="page_label">Page: </label>
                  <input type="number" id="pageNumber" className="toolbarField pageNumber" defaultValue="1" size="4" min="1" tabIndex="15" />
                    <span id="numPages" className="toolbarLabel" />
                </div>
                <div className="toolbarViewerRight">
                  <div className="splitToolbarButton">
                    <button id="zoomOut" className="toolbarButton zoomOut" title="Zoom Out" tabIndex="21" data-l10n-id="zoom_out">
                      <span data-l10n-id="zoom_out_label">Zoom Out</span>
                    </button>
                    <div className="splitToolbarButtonSeparator" />
                    <button id="zoomIn" className="toolbarButton zoomIn" title="Zoom In" tabIndex="22" data-l10n-id="zoom_in">
                      <span data-l10n-id="zoom_in_label">Zoom In</span>
                    </button>
                  </div>
                  <span id="scaleSelectContainer" className="dropdownToolbarButton">
              <select id="scaleSelect" title="Zoom" tabIndex="23" data-l10n-id="zoom" defaultValue="auto">
                <option id="pageAutoOption" title="" value="auto" data-l10n-id="page_scale_auto">Automatic Zoom</option>
                <option id="pageActualOption" title="" value="page-actual" data-l10n-id="page_scale_actual">Actual Size</option>
                <option id="pageFitOption" title="" value="page-fit" data-l10n-id="page_scale_fit">Fit Page</option>
                <option id="pageWidthOption" title="" value="page-width" data-l10n-id="page_scale_width">Full Width</option>
                <option id="customScaleOption" title="" value="custom" />
                <option title="" value="0.5">50%</option>
                <option title="" value="0.75">75%</option>
                <option title="" value="1">100%</option>
                <option title="" value="1.25">125%</option>
                <option title="" value="1.5">150%</option>
                <option title="" value="2">200%</option>
                <option title="" value="3">300%</option>
                <option title="" value="4">400%</option>
              </select>
              </span>
                </div>
              </div>
              <div id="loadingBar">
                <div className="progress">
                  <div className="glimmer">
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div id="viewerContainer" tabIndex="0">
            <div id="viewer" />
          </div>
          <div id="errorWrapper" hidden={true}>
            <div id="errorMessageLeft">
              <span id="errorMessage" />
              <button id="errorShowMore" data-l10n-id="error_more_info">
                More Information
              </button>
              <button id="errorShowLess" data-l10n-id="error_less_info" hidden={true}>
                Less Information
              </button>
            </div>
            <div id="errorMessageRight">
              <button id="errorClose" data-l10n-id="error_close">
                Close
              </button>
            </div>
            <div className="clearBoth" />
            <textarea id="errorMoreInfo" hidden={true} readOnly="readOnly" />
          </div>
        </div>

        <div id="overlayContainer" className="hidden">
          <div id="passwordOverlay" className="container hidden">
            <div className="dialog">
              <div className="row">
                <p id="passwordText" data-l10n-id="password_label">Enter the password to open this PDF file:</p>
              </div>
              <div className="row">
                <input type="password" id="password" className="toolbarField" />
              </div>
              <div className="buttonRow">
                <button id="passwordCancel" className="overlayButton"><span data-l10n-id="password_cancel">Cancel</span></button>
                <button id="passwordSubmit" className="overlayButton"><span data-l10n-id="password_ok">OK</span></button>
              </div>
            </div>
          </div>
          <div id="documentPropertiesOverlay" className="container hidden">
            <div className="dialog">
              <div className="row">
                <span data-l10n-id="document_properties_file_name">File name:</span> <p id="fileNameField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_file_size">File size:</span> <p id="fileSizeField">-</p>
              </div>
              <div className="separator" />
              <div className="row">
                <span data-l10n-id="document_properties_title">Title:</span> <p id="titleField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_author">Author:</span> <p id="authorField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_subject">Subject:</span> <p id="subjectField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_keywords">Keywords:</span> <p id="keywordsField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_creation_date">Creation Date:</span> <p id="creationDateField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_modification_date">Modification Date:</span> <p id="modificationDateField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_creator">Creator:</span> <p id="creatorField">-</p>
              </div>
              <div className="separator" />
              <div className="row">
                <span data-l10n-id="document_properties_producer">PDF Producer:</span> <p id="producerField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_version">PDF Version:</span> <p id="versionField">-</p>
              </div>
              <div className="row">
                <span data-l10n-id="document_properties_page_count">Page Count:</span> <p id="pageCountField">-</p>
              </div>
              <div className="buttonRow">
                <button id="documentPropertiesClose" className="overlayButton"><span data-l10n-id="document_properties_close">Close</span></button>
              </div>
            </div>
          </div>
        </div>
      </div>);
  }
}
