import React from "react";
import "../../../stylesheets/common/_url_viewer.scss"

export class URLViewer extends React.Component {
  constructor() {
    super();
    this.state = {
      url: "https://www.youtube.com/embed/sthMUE9fnfc",
    };
  }

  getYoutubeId = youtubeUrl => {
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
    const match = youtubeUrl.match(regExp);
    return match && match[2].length === 11 ? match[2] : null;
  };

  render() {
    return (
      <div id="url_container" key={"url_container"}>
        <div
          key="sel_box"
          id="sel_box"
          className="annotation-holder-active"
          style={{display: "none"}}
        />
        <iframe
          id="url_display"
          src={this.state.url}
        />
      </div>
    );
  }
}
