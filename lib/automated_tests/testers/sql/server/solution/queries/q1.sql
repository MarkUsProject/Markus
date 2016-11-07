DROP VIEW IF EXISTS oracle_q1 CASCADE;

CREATE VIEW oracle_q1 AS
  SELECT table1.text AS letter, table2.text AS number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id
  ORDER BY table1.id, table2.id;
