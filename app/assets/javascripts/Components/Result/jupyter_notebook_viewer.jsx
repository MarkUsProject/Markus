import React from "react";
import {markupTextInRange} from "../Helpers/range_selector";

export class JupyterNotebookViewer extends React.Component {

  constructor() {
    super();
    this.state = {
      annotations: []
    }
  }

  getSelection = () => {
    const iframe = document.getElementById("jupyter-notebook");
    const target = (iframe.contentWindow || iframe.contentDocument);
    const range = target.getSelection().getRangeAt(0);
    this.setState(prevState => ({annotations: prevState.annotations.concat([range])}));
    markupTextInRange(range, 'yellow')
  }

  render() {
    return (
      <div>
        <iframe className={'jupyter-notebook'} id={'jupyter-notebook'} src={this.props.url + '&preview=true'}/>
      </div>
    )
  }
}
