import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      url: `https://www.youtube.com/embed/${this.extract_youtube_id(this.props.web_link)}`, // Sample Youtube embed link
      //url: "https://drive.google.com/file/d/1yQh8bzo4IzmtSt-qZ0Vb-BzzEXsp45v_/preview" // sample google drive embed link
      //url: "https://play.library.utoronto.ca/watch/4493e554354a7e51bdf90f3197185b5f" // sample mymedia link
    };
  }

  extract_youtube_id = url => {
    // Taken from https://stackoverflow.com/questions/3452546/how-do-i-get-the-youtube-video-id-from-a-url
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    return match && match[7].length == 11 ? match[7] : false;
  };

  render() {
    return (
      <div className="url-container" key={"url_container"}>
        <iframe className="url-display" src={this.state.url} allowFullScreen />
      </div>
    );
  }
}
