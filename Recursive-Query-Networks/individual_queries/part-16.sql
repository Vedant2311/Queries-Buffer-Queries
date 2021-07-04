SELECT foo_outer.origin as authorid
FROM
(SELECT DISTINCT foo.origin, COUNT(origin) OVER (PARTITION BY origin) as future_collaborations
FROM
(SELECT DISTINCT origin.authorid as origin, dest.authorid as dest
FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper, all_citations
WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
AND (EXISTS (SELECT 0 FROM all_citations WHERE paperid1 = origin_paper.paperid AND paperid2 = dest_paper.paperid))
AND (NOT EXISTS (SELECT 0 FROM co_authors WHERE co_authors.origin = origin.authorid AND co_authors.dest = dest.authorid))
AND NOT(origin.authorid = dest.authorid)) AS foo
ORDER BY future_collaborations DESC, origin ASC) AS foo_outer
LIMIT 10;

