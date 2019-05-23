CREATE TABLE bad_col_count AS
  SELECT table1.word
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id;
