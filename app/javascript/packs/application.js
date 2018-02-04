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
import 'javascripts/check_timeout';
import 'javascripts/redirect';

import { ModalMarkus } from 'javascripts/modals';
import { makeTATable } from 'javascripts/Components/ta_table';
import { makeAdminTable } from 'javascripts/Components/admin_table';

import 'javascripts/react_config';


// TODO: We shouldn't need to make this a global export.
window.ModalMarkus = ModalMarkus;
window.makeAdminTable = makeAdminTable;
window.makeTATable = makeTATable;
