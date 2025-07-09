import React from "react";

export default function SearchFilter({column}) {
  return (
    <input
      placeholder={I18n.t("table.search")}
      type="text"
      onChange={e => column.setFilterValue(e.target.value)}
      value={column.getFilterValue()?.toString() || ""}
      style={{width: "100%"}}
      aria-label={I18n.t("table.search")}
    />
  );
}
