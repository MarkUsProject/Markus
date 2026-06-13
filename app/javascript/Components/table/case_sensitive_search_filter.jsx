import React from "react";

export const defaultSearchPlaceholderText = () => I18n.t("table.search");

export default function CaseSensitiveSearchFilter({column, filterValue}) {
  let caseSensitive;
  const toggleCaseSensitivity = column.columnDef.meta.toggleCaseSensitivity;
  return (
    <div style={{display: "flex", alignItems: "center", gap: "4px"}}>
      <input
        placeholder={defaultSearchPlaceholderText()}
        type="text"
        style={{flex: 1, minWidth: 0}}
        value={filterValue}
        aria-label={`${I18n.t("search")} ${column.columnDef.header || ""}`}
        onChange={event => column.setFilterValue(event.target.value)}
      />
      <label
        title={I18n.t("table.case_sensitive_search")}
        style={{display: "flex", alignItems: "center", cursor: "pointer"}}
      >
        <input
          type="checkbox"
          checked={caseSensitive}
          onChange={event => {
            toggleCaseSensitivity(event.target.checked);
          }}
          aria-label={I18n.t("table.case_sensitive_search")}
          data-testid={`${column.columnDef.id}_case_sensitive`}
        />
        <span style={{fontSize: "1.05em", marginLeft: "2px"}}>
          {I18n.t("table.case_sensitive_indicator")}
        </span>
      </label>
    </div>
  );
}
