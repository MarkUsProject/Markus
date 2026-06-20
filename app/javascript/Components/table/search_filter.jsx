import React from "react";

export const defaultSearchPlaceholderText = (header = "") => {
  return `${I18n.t("table.search")} ${header}`;
};

export default function SearchFilter({column, filterValue}) {
  return (
    <input
      placeholder={defaultSearchPlaceholderText()}
      type="text"
      onChange={e => column.setFilterValue(e.target.value)}
      value={filterValue?.toString() || ""}
      style={{width: "100%"}}
      aria-label={defaultSearchPlaceholderText(column.columnDef.header)}
    />
  );
}
