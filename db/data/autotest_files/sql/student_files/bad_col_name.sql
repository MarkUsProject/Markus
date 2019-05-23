CREATE TABLE bad_col_name AS
  SELECT table1.word AS badword, table2.number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id;
