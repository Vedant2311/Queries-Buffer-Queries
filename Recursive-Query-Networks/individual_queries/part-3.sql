SELECT dest as name
FROM
(SELECT info_paths.*, COUNT(origin) OVER (PARTITION BY origin, dest) AS rand
FROM info_paths
WHERE origin = 'Albuquerque' AND ((dest = origin and has_cycle = 1) OR (NOT(dest=origin) AND has_cycle = 0))) AS foo
WHERE rand = 1
ORDER BY name ASC;

