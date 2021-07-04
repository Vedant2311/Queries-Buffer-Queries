WITH paths_for_both_directions AS
(SELECT DISTINCT COUNT(dest) OVER (PARTITION BY origin) as count FROM info_paths_citations_both
WHERE origin = 1745 AND dest = 456 AND has_cycle = 0
UNION ALL
SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 1745 AND dest = 456 AND has_cycle=0))
THEN -1 ELSE 0 END)
)
SELECT count FROM paths_for_both_directions
LIMIT 1;

