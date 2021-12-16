// JavaScript files for the main result page (edit.html and view_marks.html).

import "javascripts/react_config";

import {makeResult} from "javascripts/Components/Result/result";
window.makeResult = makeResult;

import * as pdfjs from "pdfjs-dist";
import * as pdfjsViewer from "pdfjs-dist/web/pdf_viewer";

window.pdfjs = pdfjs;
window.pdfjsViewer = pdfjsViewer;

import "pdfjs-dist/web/pdf_viewer.css";
