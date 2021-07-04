WITH c123_inclusion_paths AS
(SELECT DISTINCT (COUNT(dest) OVER (PARTITION BY origin,dest)) AS count, -1 as query_id
FROM info_paths_collabs
WHERE origin = 3552 AND dest = 321 AND has_cycle=0
AND ((nodes LIKE concat('%,',1436,',%')) OR (nodes LIKE concat('%,',562,',%')) OR (nodes LIKE concat('%,',921,',%')))
UNION ALL
SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 3552 AND dest = 321 AND has_cycle=0))
THEN -1 ELSE 0 END),-1
)
SELECT count FROM c123_inclusion_paths
LIMIT 1;

