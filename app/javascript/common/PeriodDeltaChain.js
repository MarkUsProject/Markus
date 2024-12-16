/** PeriodDeltaChain Class */
import dayjs from "dayjs";

export default class PeriodDeltaChain {
  constructor(params) {
    this.period_root_id = params.period_root_id;
    this.date_format = params.date_format || "";
    this.period_class = params.period_class || "period";

    this.set_due_date(params.due_date);
  }

  refresh() {
    let current_time = this.due_date;
    const format = this.date_format;
    const period_rows = document
      .getElementById(this.period_root_id)
      .getElementsByClassName(this.period_class);

    for (let row of period_rows) {
      const from_time_node = row.getElementsByClassName("PeriodDeltaChain_FromTime")[0];
      from_time_node.textContent = current_time.format(format);

      const hours_value = row.getElementsByClassName("PeriodDeltaChain_Hours")[0].value;
      current_time = current_time.add(hours_value, "hours");
      const to_time_node = row.getElementsByClassName("PeriodDeltaChain_ToTime")[0];
      to_time_node.textContent = current_time.format(format);
    }
  }

  set_due_date(new_due_date) {
    this.due_date = dayjs(new_due_date, this.date_format);
    this.refresh();
  }
}
