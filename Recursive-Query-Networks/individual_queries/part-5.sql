WITH largest_cycle AS
(SELECT DISTINCT len as length, 0 as query_id
FROM info_paths
WHERE has_cycle=1 AND origin = dest
UNION ALL
SELECT NULL,0
WHERE NOT EXISTS (SELECT 0 FROM info_paths WHERE has_cycle=1 AND origin = dest)
ORDER BY length DESC
LIMIT 1)
SELECT COALESCE(length,0) AS length FROM largest_cycle;

