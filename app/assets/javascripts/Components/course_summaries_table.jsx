import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class CourseSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      grade_columns: [],
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.pop_course_summaries_path(),
      dataType: 'json',
    }).then(res => {
      //this.setState({data: res});
      let grade_column = res.map(c =>
        Object.assign({},
          c));
      this.setState({data:grade_column})
    });


  }

  nameColumns = [
    {
      Header: I18n.t('user.user_name'),
      accessor: 'user_name'
    },
    {
      Header: I18n.t('user.first_name'),
      accessor: 'first_name',
    },
    {
      Header: I18n.t('user.last_name'),
      accessor: 'last_name',
    },
  ];

  toggleAll = (a) => {
    for (let key in a) {
      //console.log(a[key])
      if (a.hasOwnProperty(key)) {
        for (let k in a[key]) {
          if (a[key].hasOwnProperty(k)) {
            return { //should be concat not return
              Header: k,
              accessor: a[key][k]
            }
          }
        }
      }
    }
  }
col = (a) => {
    console.log(a)
    var cols = []
    for( let i=1 ; i <= 8; i++ ){
      cols.concat({
        Header: 'kk',
        accessor: d => d.a[i]
      })
    }
    return cols
}
  render() {


    /*const {data} = this.state;
    //var data1 = JSON.parse(data)
      let students = data.map(student=>{
        let marks = student.assignment_marks
        for (var key in marks) {
          if (marks.hasOwnProperty(key)) {
            console.log(key + " -> " + marks[key]);
          }
        }
        let mark = student.assignment_marks.map(mark=>{
          return (
            <tr>
              <td>
                {mark}
              </td>

            </tr>
          )
        });
        return (
          <table>
            <tr>
              <td>mark</td>

            </tr>
            {marks}
          </table>
        );
      });
      return (
        <div>
          {students}
        </div>
      )
    }

*/ const {data} = this.state;
    let grade = this.state.grade_columns
console.log(data)
    var arr = new Array();

   /* for (var key in grade[0]) {
      arr.push(key);
    }
    console.log(arr)
    arr.map(name => {})*/
    //console.log(data[0].assignmet_marks)
  //console.log(this.toggleAll(this.state.grade_columns))

    let columns = data.concat(this.state.grade_columns);

   //console.log(data);
    /*let students = data.map(student=> {

      let marks = student.assignment_marks.toString();
      //console.log(marks)
      return {
        Header: marks,
        accessor: 'marks'
        //Cell: props => <div>{renderFunc(props.value, arg)}</div>
      }
      for (let key in marks) {
        if (marks.hasOwnProperty(key)) {
          return {
            Header: key,
            accessor: 'key'
            //Cell: props => <div>{renderFunc(props.value, arg)}</div>
          }
          console.log(key + " -> " + marks[key]);

        }
      }
      console.log(student.id)
    })*/
    /*const columns = Object.keys(data[0]).map((key, id)=>{
      return {
        Header: key,
        accessor: key
      }
    })*/
    return (
      <ReactTable
        data={data}
        columns={
          [
          {
            Header: I18n.t('user.user_name'),
            accessor: 'user_name',
          },
          {
            Header: I18n.t('user.first_name'),
            accessor: 'first_name'
          },
          {
            Header: I18n.t('user.last_name'),
            accessor: 'last_name'
          },
          /*{
            id: 'hi',
            header: 'hi',
            accessor: d => d.assignment_marks[2]
          },*/
          {
            Header: 'A0',
            accessor: 'assignment_marks',
            Cell: row => {
              let rows = [];
              for (let i = 1; i < 9; i++) {
                rows.push(row.row.assignment_marks[i]);
              }
              return (
                <div>
                  <span className="class-for-name">{rows[0]}</span>
                </div>
              )
            }
          },
            {
              Header: 'A1',
              accessor: 'assignment_marks',
              Cell: row => {
                let rows = [];
                for (let i = 1; i < 9; i++) {
                  rows.push(row.row.assignment_marks[i]);
                }
                return (
                  <div>
                    <span className="class-for-name">{rows[1]}</span>
                  </div>
                )
              }
            }
          ]}

      />
    );

    }

}

export function makeCourseSummaryTable(elem) {
  render(<CourseSummaryTable />, elem);
}
