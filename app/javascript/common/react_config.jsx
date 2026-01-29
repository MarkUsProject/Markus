import {I18n} from "i18n-js";
import translations from "translations.json";
import React from "react";
import {ReactTableDefaults} from "react-table";
import {faChevronDown, faChevronUp} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import {
  defaultSort,
  stringFilterMethod,
  textFilter,
  customNoDataComponent,
  customLoadingProp,
  customGetNoDataProps,
} from "../Components/Helpers/table_helpers";

const i18n = new I18n(translations);

Object.assign(ReactTableDefaults, {
  defaultPageSize: 10000,
  minRows: 0,
  className: "-highlight",
  column: {
    ...ReactTableDefaults.column,
    Expander: ({isExpanded}) => {
      if (isExpanded) {
        return (
          <span className="rt-expander-custom">
            <FontAwesomeIcon icon={faChevronUp} title={i18n.t("table.hide_details")} />
          </span>
        );
      } else {
        return (
          <span className="rt-expander-custom">
            <FontAwesomeIcon icon={faChevronDown} title={i18n.t("table.show_details")} />
          </span>
        );
      }
    },
  },
  showPagination: false,
  showPageSizeOptions: false,
  style: {maxHeight: "500px"},
  defaultSortMethod: defaultSort,
  defaultFilterMethod: stringFilterMethod,
  FilterComponent: textFilter,
  NoDataComponent: customNoDataComponent,
  getNoDataProps: customGetNoDataProps,
  LoadingComponent: customLoadingProp,
});

Object.assign(ReactTableDefaults.column, {
  Placeholder: i18n.t("search"),
});
