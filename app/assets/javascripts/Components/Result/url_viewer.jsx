import React from "react";
import "../../../stylesheets/common/_url_viewer.scss"

export class URLViewer extends React.Component {
  state = {
    url: "https://www.youtube.com/embed/sthMUE9fnfc",
  };

  render() {
    return (
      <div id="url_container" key={"url_container"}>
        <iframe
          id="url_display"
          src={this.state.url}
          allowFullScreen
        />
      </div>
    );
  }
}
