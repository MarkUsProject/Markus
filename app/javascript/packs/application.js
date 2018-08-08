/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import 'javascripts/help-system';
import 'javascripts/layouts';
import 'javascripts/menu';
import 'javascripts/redirect';

import { ModalMarkus } from 'javascripts/modals';
import { makeTATable } from 'javascripts/Components/ta_table';
import { makeAdminTable } from 'javascripts/Components/admin_table';
import { makeStudentTable } from 'javascripts/Components/student_table';
import { makeAssignmentSummaryTable } from 'javascripts/Components/assignment_summary_table';
import { makeExamScanLogTable } from 'javascripts/Components/exam_scan_log_table';
import { makeMarksSpreadsheet } from 'javascripts/Components/marks_spreadsheet';
import { makeSubmissionFileManager } from 'javascripts/Components/submission_file_manager';
import { makeRepoBrowser } from 'javascripts/Components/repo_browser';
import { makeCourseSummaryTable } from 'javascripts/Components/course_summaries_table';
import { makeTestScriptResultTable } from 'javascripts/Components/test_script_result_table';
import { makeSubmissionTable } from 'javascripts/Components/submission_table';
import { makeMarksGradersManager } from 'javascripts/Components/marks_graders_manager';
import { makeGroupsManager } from 'javascripts/Components/groups_manager';
import { makeGradersManager } from 'javascripts/Components/graders_manager';
import { makeMarkingSchemeTable } from 'javascripts/Components/marking_schemes_table';
import { makeStarterCodeFileManager } from 'javascripts/Components/starter_code_file_manager';

import 'javascripts/react_config';


// TODO: We shouldn't need to make this a global export.
window.ModalMarkus = ModalMarkus;
window.makeAdminTable = makeAdminTable;
window.makeStudentTable = makeStudentTable;
window.makeTATable = makeTATable;
window.makeAssignmentSummaryTable = makeAssignmentSummaryTable;
window.makeExamScanLogTable = makeExamScanLogTable;
window.makeMarksSpreadsheet = makeMarksSpreadsheet;
window.makeSubmissionFileManager = makeSubmissionFileManager;
window.makeRepoBrowser = makeRepoBrowser;
window.makeCourseSummaryTable = makeCourseSummaryTable;
window.makeTestScriptResultTable = makeTestScriptResultTable;
window.makeSubmissionTable = makeSubmissionTable;
window.makeMarksGradersManager = makeMarksGradersManager;
window.makeGroupsManager = makeGroupsManager;
window.makeGradersManager = makeGradersManager;
window.makeMarkingSchemeTable = makeMarkingSchemeTable;
window.makeStarterCodeFileManager = makeStarterCodeFileManager;
