import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      url: "",
      show_iframe_preview: false,
    };
  }

  componentDidMount() {
    try {
      const url = new URL(this.props.content);
      const youtube_id_is_set = this.configureYoutubePreview(url.toString());
      if (!youtube_id_is_set) {
        switch (url.hostname) {
          case "docs.google.com":
          case "drive.google.com":
            this.configureGoogleDrivePreview(url.toString());
            break;
          case "play.library.utoronto.ca":
            this.setState({
              url: url.toString(),
              show_iframe_preview: false,
            });
            break;
          default:
            this.setDefaultState();
        }
      }
    } catch (e) {
      this.setDefaultState();
    }
  }

  setDefaultState = () => {
    this.setState({
      url: "",
      show_iframe_preview: false,
    });
  }

  configureGoogleDrivePreview = url => {
    const regex = /\/d\/(.+)\//;
    const match = url.match(regex);
    if (match.length === 2) {
      this.setState({
        url: `https://drive.google.com/file/d/${match[1]}/preview`,
        show_iframe_preview: true,
      });
    } else {
      this.setDefaultState();
    }
  };

  configureYoutubePreview = url => {
    // Taken from https://stackoverflow.com/questions/3452546/how-do-i-get-the-youtube-video-id-from-a-url
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    if (match && match[7].length === 11) {
      this.setState({
        url: `https://www.youtube.com/embed/${match[7]}`,
        show_iframe_preview: true,
      });
      return true;
    }
    return false;
  };

  render() {
    if (this.state.show_iframe_preview) {
      return (
        <div className="url-container" key={"url_container"}>
          <iframe className="url-display" src={this.state.url} allowFullScreen>
            <pre>{this.props.content}</pre>
          </iframe>
        </div>
      );
    } else {
      return <pre>{this.props.content}</pre>;
    }
  }
}
