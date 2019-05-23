CREATE TABLE bad_row_count AS
  SELECT table1.word, table2.number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id
  UNION ALL
  SELECT CAST('zzzz' AS varchar(50)) AS word, CAST(9.99 AS double precision) AS number;
