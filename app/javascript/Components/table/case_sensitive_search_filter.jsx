import React from "react";

export const defaultSearchPlaceholderText = () => I18n.t("table.search");

export default function CaseSensitiveSearchFilter({column, filterValue}) {
  let caseSensitive;
  return (
    <div style={{display: "flex", alignItems: "center", gap: "4px"}}>
      <input
        placeholder={defaultSearchPlaceholderText()}
        type="text"
        style={{flex: 1, minWidth: 0}}
        value={filterValue?.filterValue ?? ""}
        aria-label={`${I18n.t("search")} ${column.columnDef.header || ""}`}
        onChange={event => {
          column.setFilterValue({
            filterValue: event.target.value,
            caseSensitive: filterValue?.caseSensitive ?? false,
          });
        }}
      />
      <label
        title={I18n.t("table.case_sensitive_search")}
        style={{display: "flex", alignItems: "center", cursor: "pointer"}}
      >
        <input
          type="checkbox"
          checked={caseSensitive}
          onChange={event => {
            column.setFilterValue({
              filterValue: filterValue?.filterValue ?? "",
              caseSensitive: event.target.checked,
            });
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
