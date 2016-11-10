SET search_path TO ate, public;

SELECT table1.text, table2.number
FROM table1 JOIN table2 ON table1.id = table2.foreign_id
UNION ALL
SELECT 'zzzz' AS text, 9.99 AS number
ORDER BY text;
