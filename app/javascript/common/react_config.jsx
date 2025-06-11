import {ReactTableDefaults} from "react-table";
import {I18n} from "i18n-js";
import translations from "translations.json";
import {
  defaultSort,
  stringFilterMethod,
  textFilter,
  customNoDataComponent,
} from "../Components/Helpers/table_helpers";

const i18n = new I18n(translations);

Object.assign(ReactTableDefaults, {
  defaultPageSize: 10000,
  minRows: 0,
  className: "-highlight",
  showPagination: false,
  showPageSizeOptions: false,
  style: {maxHeight: "500px"},
  defaultSortMethod: defaultSort,
  defaultFilterMethod: stringFilterMethod,
  FilterComponent: textFilter,
  NoDataComponent: customNoDataComponent,
});

Object.assign(ReactTableDefaults.column, {
  Placeholder: i18n.t("search"),
});
