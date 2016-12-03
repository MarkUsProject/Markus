SET search_path TO ate, public;

SELECT table1.text
FROM table1 JOIN table2 ON table1.id = table2.foreign_id
ORDER BY text;
