import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      url: "",
    };
  }

  componentDidMount() {
    this.configDisplay();
  }

  componentDidUpdate(prevProps) {
    if (prevProps.externalUrl !== this.props.externalUrl) {
      this.configDisplay();
    }
  }

  configDisplay = () => {
    try {
      const url = new URL(this.props.externalUrl);
      const youtube_view_is_set = this.configureOEmbedPreview(url.toString(), "https://www.youtube.com/oembed");
      if (!youtube_view_is_set) {
        switch (url.hostname) {
          case "docs.google.com":
          case "drive.google.com":
            this.configureGoogleDrivePreview(url);
            break;
          default:
            this.setDefaultState();
        }
      }
    } catch (e) {
      this.setDefaultState();
    }
  };

  setDefaultState = () => {
    this.setState({
      url: "",
    });
  };

  configureGoogleDrivePreview = url => {
    const path = url.pathname.split("/")
    if (path[1] === "forms") {
      url.pathname = url.pathname.replace(/(\/[^\/]+)$/, '/viewform');
    } else {
      url.pathname = url.pathname.replace(/(\/[^\/]+)$/, '/preview');
    }
    this.setState({
      url: url.toString(),
    });
  }

  configureOEmbedPreview = (url, oembedUrl) => {
    $.get(oembedUrl, {format:"json", url: url})
      .then(res => {
        const match = res.html.match(/src="(\S+)"/);
        if (match.length === 2) {
          this.setState({
            url: match[1],
          });
          return true;
        }
      })
    return false;
  }

  render() {
    if (this.state.url !== "") {
      return (
        <div className="url-container">
          <iframe className="url-display" src={this.state.url} allowFullScreen>
            <pre>{this.props.externalUrl}</pre>
          </iframe>
        </div>
      );
    } else {
      return <pre>{this.props.externalUrl}</pre>;
    }
  }
}
