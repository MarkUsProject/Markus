// JavaScript files for the main result page (edit.html and view_marks.html).

import { render } from 'react-dom';
import 'javascripts/react_config';

import { makeSubmissionFilePanel } from 'javascripts/Components/Result/submission_file_panel';
import { makeAnnotationPanel } from 'javascripts/Components/Result/annotation_panel';
import { makeFeedbackFilePanel } from 'javascripts/Components/Result/feedback_file_panel';
import { makeRemarkPanel } from 'javascripts/Components/Result/remark_panel';

window.makeSubmissionFilePanel = makeSubmissionFilePanel;
window.makeAnnotationPanel = makeAnnotationPanel;
window.makeFeedbackFilePanel = makeFeedbackFilePanel;
window.makeRemarkPanel = makeRemarkPanel;
