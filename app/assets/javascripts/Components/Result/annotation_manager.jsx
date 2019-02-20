import React from 'react';


export class AnnotationManager extends React.Component {
  componentDidMount() {
    this.props.categories.forEach(cat => {
      new DropDownMenu($(`#annotation_category_${cat.id}`),
                       $(`#annotation_text_list_${cat.id}`));
    });
  }

  render() {
    return (
      <div>
      <button id='new_annotation_button'
              onClick={this.props.newAnnotation}>
        {I18n.t('helpers.submit.create', {model: I18n.t('activerecord.models.annotation.one')})}
      </button>

      <ul className='tags' id='annotation_categories'>
        {this.props.categories.map(cat =>
           <li className='annotation_category'
               id={`annotation_category_${cat.id}`}
               key={cat.id}
               onMouseDown={e => e.preventDefault()}>
               {cat.annotation_category_name}
               <div id={`annotation_text_list_${cat.id}`}>
                 <ul className="annotation_text_list">
                   {cat.texts.map(text =>
                    <li key={`annotation_text_${text.id}`} id={`annotation_text_${text.id}`}
                        onClick={e => {
                          e.preventDefault();
                          this.props.addExistingAnnotation(text.id);
                        }}
                        onMouseDown={e => e.preventDefault()}
                        title={text.content}>
                      {text.content.slice(0, 70)}
                    </li>)}
                 </ul>
               </div>
            </li>
        )}
      </ul>
      </div>
    );
  }
}
