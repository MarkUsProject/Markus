/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_include_tag 'application_webpack' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb
import "mathjax/es5/tex-svg";

// jquery (should be the first to be loaded, as many other libs depend on it)
import $ from "jquery";
window.$ = window.jQuery = $;
import "jquery-ui/dist/jquery-ui";
import "ui-contextmenu";

// Callbacks for AJAX events (both jQuery and ujs).
import * as ajax_events from "./common/ajax_events";
window.ajax_events = ajax_events;

// vendor libraries
import "javascripts/jquery.easyModal";

// Markdown support (using marked and DOMpurify)
import safe_marked from "./common/safe_marked";
window.safe_marked = safe_marked;

// dayjs (date/times manipulation) and PeriodDeltaChain
import dayjs from "dayjs";
import customParseFormat from "dayjs/plugin/customParseFormat";
dayjs.extend(customParseFormat);
dayjs.locale(I18N_LOCALE);

import PeriodDeltaChain from "./common/PeriodDeltaChain";
window.PeriodDeltaChain = PeriodDeltaChain;

// mousetrap (keybindings)
import "mousetrap";

// rails/ujs
import Rails from "@rails/ujs";
Rails.start();
window.Rails = Rails;

// i18n-js
import {I18n} from "i18n-js";
import translations from "translations.json";
window.I18n = new I18n(translations);
window.I18n.locale = I18N_LOCALE;

// JCrop
import Jcrop from "jcrop";
window.Jcrop = Jcrop;

// chart.js
import {Chart, registerables} from "chart.js";
Chart.register(...registerables);
window.Chart = Chart;
import "./common/chart_config";

// flatpickr
import flatpickr from "flatpickr";
window.flatpickr = flatpickr;

// prism
window.Prism = window.Prism || {};
window.Prism.manual = true;
import "prismjs/plugins/line-numbers/prism-line-numbers.css";

// pdf.js
import * as pdfjs from "pdfjs-dist";
import * as pdfjsViewer from "pdfjs-dist/web/pdf_viewer.mjs";

window.pdfjs = pdfjs;
window.pdfjsViewer = pdfjsViewer;

import "pdfjs-dist/web/pdf_viewer.css";

window.Routes = require("./routes");

// create a global icon for the help system
import {icon} from "@fortawesome/fontawesome-svg-core";
import {faCircleQuestion} from "@fortawesome/free-regular-svg-icons";
window.HELP_ICON_HTML = icon(faCircleQuestion).node[0];

// assets with side-effects only
import "./common/flatpickr_config";
import "./common/fontawesome_config";
import "./common/help-system";
import "./common/layouts";
import "./common/menu";
import "./common/react_config";
import "./common/redirect";
import "./common/fetch_proxy";

// assets that export vars/functions/classes
// TODO: We shouldn't need to make everything global.
import {poll_job} from "./common/job_poller";
window.poll_job = poll_job;
import {colours} from "./common/markus_colors";
window.colours = colours;
import {set_theme} from "./common/theme_colors";
window.set_theme = set_theme;
import {refreshOrLogout} from "./common/refresh_or_logout";
window.refreshOrLogout = refreshOrLogout;
import {ModalMarkus} from "./common/modals";
window.ModalMarkus = ModalMarkus;
import {makeDashboard} from "./Components/dashboard";
window.makeDashboard = makeDashboard;
import {makeAssignmentSummary} from "./Components/assignment_summary";
window.makeAssignmentSummary = makeAssignmentSummary;
import {makeGradeEntryFormSummary} from "./Components/grade_entry_form_summary";
window.makeGradeEntryFormSummary = makeGradeEntryFormSummary;
import {makeTATable} from "./Components/ta_table";
window.makeTATable = makeTATable;
import {makeInstructorTable} from "./Components/instructor_table";
window.makeInstructorTable = makeInstructorTable;
import {makeStudentTable} from "./Components/student_table";
window.makeStudentTable = makeStudentTable;
import {makeOneTimeAnnotationsTable} from "./Components/one_time_annotations_table";
window.makeOneTimeAnnotationsTable = makeOneTimeAnnotationsTable;
import {makeExamScanLogTable} from "./Components/exam_scan_log_table";
window.makeExamScanLogTable = makeExamScanLogTable;
import {makeSubmissionFileManager} from "./Components/submission_file_manager";
window.makeSubmissionFileManager = makeSubmissionFileManager;
import {makeRepoBrowser} from "./Components/repo_browser";
window.makeRepoBrowser = makeRepoBrowser;
import {makeTestRunTable} from "./Components/test_run_table";
window.makeTestRunTable = makeTestRunTable;
import {makeSubmissionTable} from "./Components/submission_table";
window.makeSubmissionTable = makeSubmissionTable;
import {makeTagTable} from "./Components/tag_table";
window.makeTagTable = makeTagTable;
import {makeMarksGradersManager} from "./Components/marks_graders_manager";
window.makeMarksGradersManager = makeMarksGradersManager;
import {makePeerReviewsManager} from "./Components/peer_reviews_manager";
window.makePeerReviewsManager = makePeerReviewsManager;
import {makePeerReviewTable} from "./Components/peer_review_table";
window.makePeerReviewTable = makePeerReviewTable;
import {makeGroupsManager} from "./Components/groups_manager";
window.makeGroupsManager = makeGroupsManager;
import {makeGradersManager} from "./Components/graders_manager";
window.makeGradersManager = makeGradersManager;
import {makeBatchTestRunTable} from "./Components/batch_test_run_table";
window.makeBatchTestRunTable = makeBatchTestRunTable;
import {makeMarkingSchemeTable} from "./Components/marking_schemes_table";
window.makeMarkingSchemeTable = makeMarkingSchemeTable;
import {makeAutotestManager} from "./Components/autotest_manager";
window.makeAutotestManager = makeAutotestManager;
import {makeStudentPeerReviewsTable} from "./Components/student_peer_reviews_table";
window.makeStudentPeerReviewsTable = makeStudentPeerReviewsTable;
import {makeAnnotationUsagePanel} from "./Components/annotation_usage_panel";
window.makeAnnotationUsagePanel = makeAnnotationUsagePanel;
import {makeGradesSummaryDisplay} from "./Components/grades_summary_display";
window.makeGradesSummaryDisplay = makeGradesSummaryDisplay;
import {makeDataChart} from "./Components/Helpers/data_chart";
window.makeDataChart = makeDataChart;
import {makeStarterFileManager} from "./Components/starter_file_manager";
window.makeStarterFileManager = makeStarterFileManager;
import {makeNotesTable} from "./Components/notes_table";
window.makeNotesTable = makeNotesTable;
import {makeAdminCourseList} from "./Components/admin_course_list";
window.makeAdminCourseList = makeAdminCourseList;
import {makeAdminUsersList} from "./Components/admin_users_list";
window.makeAdminUsersList = makeAdminUsersList;
import {makeCourseList} from "./Components/course_list";
window.makeCourseList = makeCourseList;
import {makeSubmitViewTokenModal} from "./Components/Modals/submit_view_token_modal";
window.makeSubmitViewTokenModal = makeSubmitViewTokenModal;
import {makeLtiSettings} from "./Components/lti_settings";
window.makeLtiSettings = makeLtiSettings;
import {makeResult} from "./Components/Result/result";
window.makeResult = makeResult;
import {createConsumer} from "@rails/actioncable";
window.createConsumer = createConsumer;
import {renderFlashMessages} from "./common/flash";
window.renderFlashMessages = renderFlashMessages;
