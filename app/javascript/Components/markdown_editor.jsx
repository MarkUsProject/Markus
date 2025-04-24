import React from "react";
import MarkdownPreview from "./markdown_preview";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

import PropTypes from "prop-types";

export default class MarkdownEditor extends React.Component {
  render() {
    return (
      <Tabs disableUpDownKeys>
        <TabList>
          <Tab>{I18n.t("write")}</Tab>
          <Tab>{I18n.t("preview")}</Tab>
        </TabList>
        <TabPanel forceRender>
          <label>
            <textarea
              required={true}
              id={this.props.text_area_id}
              name="content"
              placeholder={I18n.t("results.annotation.placeholder")}
              value={this.props.content}
              onChange={this.props.handleChange}
              rows="8"
              autoFocus={true}
            />
          </label>

          <div
            className={this.props.show_autocomplete ? "" : "hidden"}
            data-testid="markdown-editor-autocomplete-root"
          >
            <ul className="tags" key="auto_completion_category">
              <li className="annotation_category">
                <p id={this.props.auto_completion_text_id}></p>
                <div>
                  <ul id={this.props.auto_completion_list_id}></ul>
                </div>
              </li>
            </ul>
          </div>
        </TabPanel>
        <TabPanel>
          <MarkdownPreview
            id="markdown-preview"
            content={this.props.content}
            updateAnnotationCompletion={this.props.updateAnnotationCompletion}
          />
        </TabPanel>
      </Tabs>
    );
  }
}

MarkdownEditor.propTypes = {
  content: PropTypes.string.isRequired,
  handleChange: PropTypes.func.isRequired,
  show_autocomplete: PropTypes.bool.isRequired,
  text_area_id: PropTypes.string,
  auto_completion_text_id: PropTypes.string,
  auto_completion_list_id: PropTypes.string,
  updateAnnotationCompletion: PropTypes.func,
};
