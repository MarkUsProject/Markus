import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      url: "",
      isInvalidUrl: false
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
            this.setState({url: ""});
        }
      }
      this.setState({isInvalidUrl: false});
    } catch (e) {
      this.setState({
        url: "",
        isInvalidUrl: true
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
      url: url.toString(),
    });
  };

  configureOEmbedPreview = (url, oembedUrl) => {
    $.get(oembedUrl, {format: "json", url: url}).then(res => {
      const match = res.html.match(/src="(\S+)"/);
      if (match.length === 2) {
        this.setState({
          url: match[1],
        });
        return true;
      }
    });
    return false;
  };

  renderPreviewDisplay = () => {
    if (this.state.url !== "") {
      return (
        <iframe className="url-display" src={this.state.url} allowFullScreen>
          {I18n.t("submissions.url_display_error")}
        </iframe>
      )
    } else {
      return I18n.t("submissions.unsupported_url", { host: "sample.com"} );
    }
  }

  render() {
    if (this.state.isInvalidUrl) {
      return <pre>{this.props.externalUrl}</pre>
    } else {
      return (
        <div className="url-container">
          <div className="link-bar">
            <a className="link-display" href={this.props.externalUrl} target="_blank">{this.props.externalUrl}</a>
          </div>
          <div className="display-area">
            {this.renderPreviewDisplay()}
          </div>
        </div>
      )
    }
  }
}
