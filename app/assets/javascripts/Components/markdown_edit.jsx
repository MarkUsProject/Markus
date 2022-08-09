import React from "react";
import MarkdownPreview from "./markdown_preview";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

import PropTypes from "prop-types";

export default class MarkdownEdit extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      content: this.props.content,
      annotation_text_id: "",
    };
  }

  handleChange = event => {
    this.setState({content: event.target.value});
    this.props.handleChange(event);
  };

  render() {
    return (
      <Tabs disableUpDownKeys>
        <TabList>
          <Tab id="write-tab">{I18n.t("write")}</Tab>
          <Tab id="preview-tab">{I18n.t("preview")}</Tab>
        </TabList>
        <TabPanel forceRender>
          <label>
            <textarea
              required={true}
              id="new_annotation_content"
              name="content"
              placeholder={I18n.t("results.annotation.placeholder")}
              value={this.state.content}
              onChange={this.handleChange}
              rows="8"
              autoFocus={true}
            />
          </label>

          <div className={this.props.show_autocomplete ? "" : "hidden"}>
            <ul className="tags" key="annotation_completion" id="annotation_completion">
              <li className="annotation_category" id="annotation_completion_li">
                <p id="annotation_completion_text"></p>
                <div>
                  <ul id="annotation_text_list"></ul>
                </div>
              </li>
            </ul>
          </div>
          <input
            type="hidden"
            id="annotation_text_id"
            name="annotation_text_id"
            value={this.props.annotation_text_id}
          />
        </TabPanel>
        <TabPanel>
          <MarkdownPreview
            id="markdown-preview"
            content={this.state.content}
            updateAnnotationCompletion={this.props.updateAnnotationCompletion}
          />
        </TabPanel>
      </Tabs>
    );
  }
}

MarkdownEdit.propTypes = {
  annotation_text_id: PropTypes.string,
  content: PropTypes.string.isRequired,
  handleChange: PropTypes.func.isRequired,
  show_autocomplete: PropTypes.bool,
  updateAnnotationCompletion: PropTypes.func,
};
