SELECT authorid, length
FROM
(SELECT all_authors.authorid, COALESCE(shortest_paths.length,-1) as length
FROM all_authors LEFT OUTER JOIN
(SELECT dest as authorid, length
FROM
(SELECT foo.*, row_number() OVER (PARTITION BY dest) as rand
FROM
(SELECT DISTINCT origin, dest, nodes, len as length
FROM info_paths_collabs
WHERE origin = 1235 AND has_cycle=0 AND NOT(dest = origin)
ORDER BY dest ASC, len ASC) AS foo) AS foo_outer
WHERE rand = 1) AS shortest_paths
ON shortest_paths.authorid = all_authors.authorid) AS temp_table
WHERE NOT(authorid=1235)
ORDER BY length DESC, authorid ASC;

