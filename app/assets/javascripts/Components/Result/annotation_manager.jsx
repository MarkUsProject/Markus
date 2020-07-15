import React from 'react';


export class AnnotationManager extends React.Component {
  componentDidMount() {
    this.props.categories.forEach(cat => {
      new DropDownMenu($(`#annotation_category_${cat.id}`),
                       $(`#annotation_text_list_${cat.id}`));
    });
  }

  componentDidUpdate(prevProps, prevState, snapshot) {
    this.props.categories.forEach(cat => {
      let list = $(`#annotation_text_list_${cat.id}`)[0].getBoundingClientRect();
      let panel = $('.react-tabs-panel-action-bar')[0].getBoundingClientRect();
      console.log(list)
      console.log(panel)
      console.log(list.width > panel.right - list.left)
      if (list.width > panel.right - list.left) {
        $(`#annotation_text_list_${cat.id}`)[0].style.position = relative;
        $(`#annotation_text_list_${cat.id}`)[0].style.right = panel.right - list.left;
      }
    });
  }

  render() {
    return [
      <button key='new_annotation_button'
              onClick={this.props.newAnnotation}>
        {I18n.t('helpers.submit.create', {model: I18n.t('activerecord.models.annotation.one')})}
      </button>,
      <ul className='tags' key='annotation_categories'>
        {this.props.categories.map(cat =>
           <li className='annotation_category'
               id={`annotation_category_${cat.id}`}
               key={cat.id}
               onMouseDown={e => e.preventDefault()}>
               {cat.annotation_category_name}
               <div id={`annotation_text_list_${cat.id}`}>
                 <ul>
                   {cat.texts.map(text =>
                    <li key={`annotation_text_${text.id}`} id={`annotation_text_${text.id}`}
                        onClick={e => {
                          e.preventDefault();
                          this.props.addExistingAnnotation(text.id);
                        }}
                        onMouseDown={e => e.preventDefault()}
                        title={text.content}>
                      <span className={"text-content"}>{text.content.slice(0, 70)}</span>
                      <span className={"red-text"}>
                        {!text.deduction ? '' : '-' + text.deduction}
                      </span>
                    </li>)}
                 </ul>
               </div>
            </li>
        )}
      </ul>
    ];
  }
}
