CREATE TABLE bad_col_type AS
  SELECT table1.word, table2.id AS number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id;
