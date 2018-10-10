/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// jquery (should be the first to be loaded, as many other libs depend on it)
import $ from 'jquery/src/jquery';
window.$ = window.jQuery = $;

// vendor libraries
import 'javascripts/jquery.easyModal';

// marked (markdown support)
import marked from 'marked';
window.marked = marked;

// moment (date/times manipulation)
import moment from 'moment';
window.moment = moment;

// mousetrap (keybindings)
import 'mousetrap';

// rails-ujs
import Rails from 'rails-ujs';
Rails.start();

// i18n-js
import * as I18n from 'i18n-js';
window.I18n = I18n;
require('translations');

// chart.js
import { Chart } from 'chart.js';
import 'javascripts/chart_config';

// assets with side-effects only
import 'javascripts/help-system';
import 'javascripts/layouts';
import 'javascripts/menu';
import 'javascripts/react_config';
import 'javascripts/redirect';

// assets that export vars/functions/classes
// TODO: We shouldn't need to make everything global.
import { poll_job } from 'javascripts/job_poller';
window.poll_job = poll_job;
import { colours } from 'javascripts/markus_colors';
window.colours = colours;
import { refreshOrLogout } from 'javascripts/refresh_or_logout';
window.refreshOrLogout = refreshOrLogout;
import { ModalMarkus } from 'javascripts/modals';
window.ModalMarkus = ModalMarkus;
import { makeTATable } from 'javascripts/Components/ta_table';
window.makeTATable = makeTATable;
import { makeAdminTable } from 'javascripts/Components/admin_table';
window.makeAdminTable = makeAdminTable;
import { makeStudentTable } from 'javascripts/Components/student_table';
window.makeStudentTable = makeStudentTable;
import { makeAssignmentSummaryTable } from 'javascripts/Components/assignment_summary_table';
window.makeAssignmentSummaryTable = makeAssignmentSummaryTable;
import { makeExamScanLogTable } from 'javascripts/Components/exam_scan_log_table';
window.makeExamScanLogTable = makeExamScanLogTable;
import { makeMarksSpreadsheet } from 'javascripts/Components/marks_spreadsheet';
window.makeMarksSpreadsheet = makeMarksSpreadsheet;
import { makeSubmissionFileManager } from 'javascripts/Components/submission_file_manager';
window.makeSubmissionFileManager = makeSubmissionFileManager;
import { makeRepoBrowser } from 'javascripts/Components/repo_browser';
window.makeRepoBrowser = makeRepoBrowser;
import { makeCourseSummaryTable } from 'javascripts/Components/course_summaries_table';
window.makeCourseSummaryTable = makeCourseSummaryTable;
import { makeTestScriptResultTable } from 'javascripts/Components/test_script_result_table';
window.makeTestScriptResultTable = makeTestScriptResultTable;
import { makeSubmissionTable } from 'javascripts/Components/submission_table';
window.makeSubmissionTable = makeSubmissionTable;
import { makeMarksGradersManager } from 'javascripts/Components/marks_graders_manager';
window.makeMarksGradersManager = makeMarksGradersManager;
import { makeGroupsManager } from 'javascripts/Components/groups_manager';
window.makeGroupsManager = makeGroupsManager;
import { makeGradersManager } from 'javascripts/Components/graders_manager';
window.makeGradersManager = makeGradersManager;
import { makeBatchTestRunTable } from 'javascripts/Components/batch_test_run_table';
window.makeBatchTestRunTable = makeBatchTestRunTable;
import { makeMarkingSchemeTable } from 'javascripts/Components/marking_schemes_table';
window.makeMarkingSchemeTable = makeMarkingSchemeTable;
import { makeStarterCodeFileManager } from 'javascripts/Components/starter_code_file_manager';
window.makeStarterCodeFileManager = makeStarterCodeFileManager;
