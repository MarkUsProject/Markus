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
    const file_pattern = /^\[InternetShortcut]\nURL=/;
    const internet_shortcut = this.props.content.replace(file_pattern, "");
    const youtube_id_is_set = this.configure_youtube_preview(internet_shortcut);
    if (!youtube_id_is_set) {
      const url = new URL(internet_shortcut);
      switch (url.hostname) {
        case "docs.google.com":
        case "drive.google.com":
          this.configure_google_drive_preview(internet_shortcut);
          break;
        case "play.library.utoronto.ca":
          this.setState({
            url: internet_shortcut,
            show_iframe_preview: false,
          });
          break;
        default:
          this.setState({
            url: "",
            show_iframe_preview: false,
          });
      }
    }
  }

  configure_google_drive_preview = url => {
    const regex = /\/d\/(.+)\//;
    const match = url.match(regex);
    if (match.length === 2) {
      this.setState({
        url: `https://drive.google.com/file/d/${match[1]}/preview`,
        show_iframe_preview: true,
      });
    } else {
      this.setState({
        url: "",
        show_iframe_preview: false,
      });
    }
  };

  configure_youtube_preview = url => {
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
