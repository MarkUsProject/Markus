CREATE TABLE oracle_badnumcolumns AS
  SELECT table1.text, table2.number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id
  ORDER BY text;
