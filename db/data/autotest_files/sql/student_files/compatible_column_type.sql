CREATE TABLE compatible_column_type AS
  SELECT CAST(table1.word AS text) AS word, CAST(table2.number AS real) AS number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id;
