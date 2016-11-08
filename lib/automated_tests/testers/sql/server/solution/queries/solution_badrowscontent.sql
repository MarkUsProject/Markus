DROP TABLE IF EXISTS oracle_badrowscontent CASCADE;

CREATE TABLE oracle_badrowscontent AS
  SELECT table1.text, table2.number
  FROM table1 JOIN table2 ON table1.id = table2.foreign_id
  ORDER BY table1.id, table2.id;
