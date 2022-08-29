/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_include_tag 'application_webpack' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// jquery (should be the first to be loaded, as many other libs depend on it)
import $ from "jquery/src/jquery";
window.$ = window.jQuery = $;

// Callbacks for AJAX events (both jQuery and ujs).
import * as ajax_events from "javascripts/ajax_events";
window.ajax_events = ajax_events;

// vendor libraries
import "javascripts/jquery.easyModal";

// Markdown support (using marked and DOMpurify)
import safe_marked from "javascripts/safe_marked";
window.safe_marked = safe_marked;

// moment (date/times manipulation)
import moment from "moment";
window.moment = moment;

// mousetrap (keybindings)
import "mousetrap";

// rails/ujs
import Rails from "@rails/ujs";
Rails.start();
window.Rails = Rails;

// i18n-js
import * as I18n from "i18n-js";
import "translations";
window.I18n = I18n;

// JCrop
import Jcrop from "jcrop";
window.Jcrop = Jcrop;

// chart.js
import {Chart, registerables} from "chart.js";
Chart.register(...registerables);
window.Chart = Chart;
import "javascripts/chart_config";

// flatpickr
import flatpickr from "flatpickr";
window.flatpickr = flatpickr;

window.Routes = require("./routes");

// assets with side-effects only
import "javascripts/flatpickr_config";
import "javascripts/help-system";
import "javascripts/layouts";
import "javascripts/menu";
import "javascripts/react_config";
import "javascripts/redirect";

// assets that export vars/functions/classes
// TODO: We shouldn't need to make everything global.
import {poll_job} from "javascripts/job_poller";
window.poll_job = poll_job;
import {colours} from "javascripts/markus_colors";
window.colours = colours;
import {set_theme} from "javascripts/theme_colors";
window.set_theme = set_theme;
import {refreshOrLogout} from "javascripts/refresh_or_logout";
window.refreshOrLogout = refreshOrLogout;
import {ModalMarkus} from "javascripts/modals";
window.ModalMarkus = ModalMarkus;
import {makeDashboard} from "javascripts/Components/dashboard";
window.makeDashboard = makeDashboard;
import {makeAssignmentSummary} from "javascripts/Components/assignment_summary";
window.makeAssignmentSummary = makeAssignmentSummary;
import {makeGradeEntryFormSummary} from "javascripts/Components/grade_entry_form_summary";
window.makeGradeEntryFormSummary = makeGradeEntryFormSummary;
import {makeTATable} from "javascripts/Components/ta_table";
window.makeTATable = makeTATable;
import {makeInstructorTable} from "javascripts/Components/instructor_table";
window.makeInstructorTable = makeInstructorTable;
import {makeStudentTable} from "javascripts/Components/student_table";
window.makeStudentTable = makeStudentTable;
import {makeOneTimeAnnotationsTable} from "javascripts/Components/one_time_annotations_table";
window.makeOneTimeAnnotationsTable = makeOneTimeAnnotationsTable;
import {makeExamScanLogTable} from "javascripts/Components/exam_scan_log_table";
window.makeExamScanLogTable = makeExamScanLogTable;
import {makeSubmissionFileManager} from "javascripts/Components/submission_file_manager";
window.makeSubmissionFileManager = makeSubmissionFileManager;
import {makeRepoBrowser} from "javascripts/Components/repo_browser";
window.makeRepoBrowser = makeRepoBrowser;
import {makeTestRunTable} from "javascripts/Components/test_run_table";
window.makeTestRunTable = makeTestRunTable;
import {makeSubmissionTable} from "javascripts/Components/submission_table";
window.makeSubmissionTable = makeSubmissionTable;
import {makeTagTable} from "javascripts/Components/tag_table";
window.makeTagTable = makeTagTable;
import {makeMarksGradersManager} from "javascripts/Components/marks_graders_manager";
window.makeMarksGradersManager = makeMarksGradersManager;
import {makePeerReviewsManager} from "javascripts/Components/peer_reviews_manager";
window.makePeerReviewsManager = makePeerReviewsManager;
import {makePeerReviewTable} from "javascripts/Components/peer_review_table";
window.makePeerReviewTable = makePeerReviewTable;
import {makeGroupsManager} from "javascripts/Components/groups_manager";
window.makeGroupsManager = makeGroupsManager;
import {makeGradersManager} from "javascripts/Components/graders_manager";
window.makeGradersManager = makeGradersManager;
import {makeBatchTestRunTable} from "javascripts/Components/batch_test_run_table";
window.makeBatchTestRunTable = makeBatchTestRunTable;
import {makeMarkingSchemeTable} from "javascripts/Components/marking_schemes_table";
window.makeMarkingSchemeTable = makeMarkingSchemeTable;
import {makeAutotestManager} from "javascripts/Components/autotest_manager";
window.makeAutotestManager = makeAutotestManager;
import {makeStudentPeerReviewsTable} from "javascripts/Components/student_peer_reviews_table";
window.makeStudentPeerReviewsTable = makeStudentPeerReviewsTable;
import {makeAnnotationUsagePanel} from "javascripts/Components/annotation_usage_panel";
window.makeAnnotationUsagePanel = makeAnnotationUsagePanel;
import {makeGradesSummaryDisplay} from "javascripts/Components/grades_summary_display";
window.makeGradesSummaryDisplay = makeGradesSummaryDisplay;
import {makeDataChart} from "javascripts/Components/Helpers/data_chart";
window.makeDataChart = makeDataChart;
import {makeStarterFileManager} from "javascripts/Components/starter_file_manager";
window.makeStarterFileManager = makeStarterFileManager;
import {makeNotesTable} from "javascripts/Components/notes_table";
window.makeNotesTable = makeNotesTable;
import {makeAdminCourseList} from "javascripts/Components/admin_course_list";
window.makeAdminCourseList = makeAdminCourseList;
import {makeAdminUsersList} from "javascripts/Components/admin_users_list";
window.makeAdminUsersList = makeAdminUsersList;
import {makeCourseList} from "javascripts/Components/course_list";
window.makeCourseList = makeCourseList;
import {makeSubmitViewTokenModal} from "javascripts/Components/Modals/submit_view_token_modal";
window.makeSubmitViewTokenModal = makeSubmitViewTokenModal;
