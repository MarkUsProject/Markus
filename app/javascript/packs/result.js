// JavaScript files for the main result page (edit.html and view_marks.html).

import { render } from 'react-dom';
import 'javascripts/react_config';
import { makeAnnotationManager } from 'javascripts/Components/Result/annotation_manager';
import { makeFileViewer } from 'javascripts/Components/Result/file_viewer';
import { makeAnnotationPanel } from 'javascripts/Components/Result/annotation_panel';

window.makeAnnotationManager = makeAnnotationManager;
window.makeFileViewer = makeFileViewer;
window.makeAnnotationPanel = makeAnnotationPanel;
