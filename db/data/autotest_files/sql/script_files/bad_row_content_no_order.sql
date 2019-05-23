CREATE TABLE bad_row_content_no_order (
  word varchar(50),
  number double precision
);

INSERT INTO bad_row_content_no_order
  SELECT table1.word, table2.number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id;
