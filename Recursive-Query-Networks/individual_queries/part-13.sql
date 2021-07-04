WITH age_gender_paths AS
(SELECT DISTINCT (COUNT(dest) OVER (PARTITION BY origin,dest)) AS count, -1 as query_id
FROM info_paths_collabs_ang
WHERE origin = 1558 AND dest = 2826 AND has_cycle=0
UNION ALL
SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 1558 AND dest = 2826 AND has_cycle=0))
THEN -1 ELSE 0 END),-1
)
SELECT count FROM age_gender_paths
LIMIT 1;

