import React from "react";

export const defaultSearchPlaceholderText = () => I18n.t("table.search");

export default function SearchFilter({column, filterValue}) {
  return (
    <input
      placeholder={defaultSearchPlaceholderText()}
      type="text"
      onChange={e => column.setFilterValue(e.target.value)}
      value={filterValue?.toString() || ""}
      style={{width: "100%"}}
      aria-label={`${I18n.t("search")} ${column.columnDef.header || ""}`}
    />
  );
}
