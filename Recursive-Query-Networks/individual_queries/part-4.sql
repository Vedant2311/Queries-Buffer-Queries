WITH largest_cycle_abq AS
(SELECT DISTINCT len AS length, 0 AS query_id
FROM info_paths
WHERE has_cycle=1 AND origin = dest AND (nodes LIKE concat('%,','Albuquerque',',%'))
UNION ALL
SELECT NULL,0
WHERE NOT EXISTS (SELECT 0 FROM info_paths WHERE has_cycle=1 AND origin = dest AND (nodes LIKE concat('%,','Albuquerque',',%')))
ORDER BY length DESC
LIMIT 1)
SELECT COALESCE(length,0) AS length FROM largest_cycle_abq;

