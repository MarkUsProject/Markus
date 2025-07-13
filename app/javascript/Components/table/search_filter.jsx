import React from "react";

export const defaultSearchPlaceholderText = () => I18n.t("table.search");

export default function SearchFilter({column}) {
  return (
    <input
      placeholder={defaultSearchPlaceholderText()}
      type="text"
      onChange={e => column.setFilterValue(e.target.value)}
      value={column.getFilterValue()?.toString() || ""}
      style={{width: "100%"}}
      aria-label={defaultSearchPlaceholderText()}
    />
  );
}
