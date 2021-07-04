WITH abq_chicago_paths AS
(SELECT DISTINCT rand as count, 0 as query_id
FROM
(SELECT info_paths.*, COUNT(origin) OVER (PARTITION BY origin, dest) AS rand
FROM info_paths
WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND ((has_cycle = 0))
AND nodes LIKE concat('%,','Washington',',%')) AS foo
UNION ALL
SELECT NULL,0
WHERE NOT EXISTS (SELECT 0 FROM info_paths WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND ((has_cycle = 0)) AND nodes LIKE concat('%,','Washington',',%')))
SELECT COALESCE(count,0) AS count FROM abq_chicago_paths;

