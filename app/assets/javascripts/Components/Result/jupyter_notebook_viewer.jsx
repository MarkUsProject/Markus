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
    const range = target.getSelection().getRangeAt(0)
    this.setState(prevState => ({annotations: prevState.annotations.concat([range])}))
    markupTextInRange(range, 'yellow')
  }

  render() {
    return (
      <div>
        {/*<button onClick={this.getSelection}>{'highlight'}</button>*/ /*TODO: use annotations instead*/ }
        <iframe className={'jupyter-notebook'} id={'jupyter-notebook'} srcDoc={this.props.content}/>
      </div>
    )
  }
}
