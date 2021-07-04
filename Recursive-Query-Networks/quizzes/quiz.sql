--1--

--2--
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.authorid as origin, dest.authorid as dest, 1 as len, 
	 	concat(',', origin.authorid, ',', dest.authorid, ',') as nodes,
	 	(CASE WHEN origin.authorid = dest.authorid THEN 1 ELSE 0 END) AS has_cycle, 
	 	(CASE WHEN dest.city = 'Delhi' THEN 1 ELSE 0 END) as has_delhi, 
	 	0 as has_mumbai, 0 as has_path
	 FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.authorid as dest, len + 1,
	 	concat(get_paths.nodes, dest.authorid, ','),
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.authorid,',%') THEN 1 ELSE 0 END) AS has_cycle,
	 	(CASE WHEN ((origin.city = 'Delhi') OR get_paths.has_delhi = 1)  THEN 1 ELSE 0 END) as has_delhi,
	 	(CASE WHEN ((get_paths.has_delhi = 1 AND origin.city = 'Mumbai') OR (get_paths.has_mumbai = 1)) THEN 1 ELSE 0 END) as has_mumbai,
	 	(CASE WHEN ((has_delhi = 1 AND has_mumbai = 1) OR (get_paths.has_path = 1)) THEN 1 ELSE 0 END) AS has_path
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	)
SELECT DISTINCT COUNT(origin) OVER (PARTITION BY origin,dest) as count FROM get_paths
WHERE origin = 1 AND dest = 5 AND has_cycle = 0 AND ((has_path = 1) OR (has_delhi = 1 AND has_mumbai = 1))
UNION ALL
	SELECT (CASE WHEN (NOT EXISTS (SELECT 0 FROM get_paths WHERE origin = 1 AND dest = 5 AND has_cycle = 0))
	THEN 0 ELSE -1 END) as count
LIMIT 1;

--3--
