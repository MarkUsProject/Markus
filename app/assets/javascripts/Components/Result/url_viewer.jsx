import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      url: "",
      embeddedURL: "",
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
      const youtube_view_is_set = this.configureOEmbedPreview(
        url.toString(),
        "https://www.youtube.com/oembed"
      );
      if (!youtube_view_is_set) {
        switch (url.hostname) {
          case "docs.google.com":
          case "drive.google.com":
            this.configureGoogleDrivePreview(url);
            break;
          default:
            this.setState({embeddedURL: ""});
        }
      }
      this.setState({url: this.props.externalUrl});
    } catch (e) {
      this.setState({
        url: "",
        embeddedURL: "",
      });
    }
  };

  configureGoogleDrivePreview = url => {
    const path = url.pathname.split("/");
    if (path[1] === "forms") {
      url.pathname = url.pathname.replace(/(\/[^\/]+)$/, "/viewform");
    } else {
      url.pathname = url.pathname.replace(/(\/[^\/]+)$/, "/preview");
    }
    this.setState({
      embeddedURL: url.toString(),
    });
  };

  configureOEmbedPreview = (url, oembedUrl) => {
    $.get(oembedUrl, {format: "json", url: url}).then(res => {
      const match = res.html.match(/src="(\S+)"/);
      if (match.length === 2) {
        this.setState({
          embeddedURL: match[1],
        });
        return true;
      }
    });
    return false;
  };

  renderPreviewDisplay = () => {
    if (this.state.embeddedURL !== "") {
      return (
        <iframe className="url-display" src={this.state.embeddedURL} allowFullScreen>
          <div className="url-message-display">{I18n.t("submissions.url_display_error")}</div>
        </iframe>
      );
    } else if (this.state.url !== "") {
      const url_host = new URL(this.props.externalUrl).hostname;
      return (
        <div className="url-message-display">
          {I18n.t("submissions.unsupported_url", {host: url_host})}
        </div>
      );
    }
  };

  render() {
    if (this.state.url !== "") {
      return (
        <div className="url-container">
          <div className="link-bar">
            <a className="link-display" href={this.state.url} target="_blank">
              {this.state.url}
            </a>
          </div>
          <div className="display-area">{this.renderPreviewDisplay()}</div>
        </div>
      );
    } else {
      return <div className="url-message-display">{this.props.externalUrl}</div>;
    }
  }
}
