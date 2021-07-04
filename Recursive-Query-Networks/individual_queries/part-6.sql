WITH abq_chicago_interstate AS
(SELECT DISTINCT COUNT(origin) OVER (PARTITION BY (origin,dest)) AS count, 0 as query_id
FROM info_paths_interstate
WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND has_cycle = 0
UNION ALL
SELECT NULL,0
WHERE NOT EXISTS (SELECT 0 FROM info_paths_interstate WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND has_cycle = 0))
SELECT COALESCE(count,0) AS count FROM abq_chicago_interstate;

