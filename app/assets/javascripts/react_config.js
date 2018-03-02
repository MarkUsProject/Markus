import { ReactTableDefaults } from 'react-table';


Object.assign(ReactTableDefaults, {
  defaultPageSize: 10000,
  minRows: 0,
  className: '-highlight',
  showPagination: false,
  showPageSizeOptions: false,
  style: { maxHeight: '500px'}
});
