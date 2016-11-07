DROP VIEW IF EXISTS oracle_q2 CASCADE;

CREATE VIEW oracle_q2 AS
  SELECT CONCAT(table1.text, table2.text) AS letternumber
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id
  ORDER BY table1.id, table2.id;
