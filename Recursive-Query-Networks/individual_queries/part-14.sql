WITH cited_p126_paths AS
(SELECT DISTINCT (COUNT(dest) OVER (PARTITION BY origin,dest)) AS count, -1 as query_id
FROM info_paths_cited_126
WHERE origin = 704 AND dest = 102 AND any_citation_126 = 1 AND has_cycle = 0
UNION ALL
SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 704 AND dest = 102 AND has_cycle=0))
THEN -1 ELSE 0 END),-1
)
SELECT count from cited_p126_paths
LIMIT 1;

