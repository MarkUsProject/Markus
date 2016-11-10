SET search_path TO ate, public;

SELECT CONCAT(table1.text, 'X') AS text, table2.number
FROM table1 JOIN table2 ON table1.id = table2.foreign_id
ORDER BY text;
