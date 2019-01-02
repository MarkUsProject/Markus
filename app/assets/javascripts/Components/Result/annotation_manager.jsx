import React from 'react';
import {render} from 'react-dom';


class AnnotationManager extends React.Component {
  constructor() {
    super();
    this.state = {
      categories: [],
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  componentDidUpdate() {
    this.state.categories.forEach(cat => {
      new DropDownMenu($(`#annotation_category_${cat.id}`),
                       $(`#annotation_text_list_${cat.id}`));
    });
  }

  fetchData = () => {
    $.ajax({
      url: Routes.assignment_annotation_categories_path(this.props.assignment_id),
      dataType: 'json',
    }).then(data => {
      this.setState({categories: data});
    });
  };

  make_new_annotation = () => {
    let data = {
      submission_file_id: document.getElementById('select_file_id').value,
      result_id: this.props.result_id,
      assignment_id: this.props.assignment_id
    };

    data = this.extend_with_selection_data(data);
    if (data) {
      $.get(Routes.new_annotation_path(), data);
    }
  };

  add_existing_annotation = (annotation_text_id) => {
    let data = {
      submission_file_id: document.getElementById('select_file_id').value,
      annotation_text_id: annotation_text_id,
      result_id: this.props.result_id
    };

    data = this.extend_with_selection_data(data);
    if (data) {
      $.post(Routes.add_existing_annotation_annotations_path(), data);
    }
  };

  extend_with_selection_data = (annotation_data) => {
    let box;
    if (annotation_type === ANNOTATION_TYPES.IMAGE) {
      box = get_image_annotation_data();
    } else if (annotation_type === ANNOTATION_TYPES.PDF) {
      box = get_pdf_annotation_data();
    } else {
      box = get_text_annotation_data();
    }
    if (box) {
      return Object.assign(annotation_data, box);
    }
  };

  render() {
    return (
      <div>
      <button id='new_annotation_button'
              onClick={this.make_new_annotation}>
        {I18n.t('helpers.submit.create', {model: I18n.t('activerecord.models.annotation.one')})}
      </button>

      <ul className='tags' id='annotation_categories'>
        {this.state.categories.map(cat =>
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
                          this.add_existing_annotation(text.id);
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


export function makeAnnotationManager(elem, props) {
  return render(<AnnotationManager {...props}/>, elem);
}
