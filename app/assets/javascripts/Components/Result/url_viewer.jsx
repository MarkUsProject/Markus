import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    //TODO: Remove state url and replace its usage with url props when backend is working
    this.state = {
      url: "https://www.youtube.com/embed/dQw4w9WgXcQ", // Sample Youtube embed link
      //url: "https://drive.google.com/file/d/1yQh8bzo4IzmtSt-qZ0Vb-BzzEXsp45v_/preview" // sample google drive embed link
      //url: "https://play.library.utoronto.ca/watch/4493e554354a7e51bdf90f3197185b5f" // sample mymedia link
    };
  }

  render() {
    return (
      <div className="url-container" key={"url_container"}>
        <iframe className="url-display" src={this.state.url} allowFullScreen />
      </div>
    );
  }
}
