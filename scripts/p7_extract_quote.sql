SELECT 
  x AS before
  ,SUBSTRING(x 
       ,LEN(x) - (LEN(LTRIM(REPLACE(x, ',', ' ')) + '|') - 1) + 1 --start_pos
       ,LEN(LTRIM(REPLACE(x, ',', ' '))) --length
       ) AS after
FROM 
(
SELECT 'test'     AS x UNION ALL
SELECT ','        AS x UNION ALL
SELECT ',test'    AS x UNION ALL
SELECT 'test,'    AS x UNION ALL
SELECT ',test,'   AS x UNION ALL
SELECT ',,test'   AS x UNION ALL
SELECT 'test,,'   AS x UNION ALL
SELECT ',,test,,' AS x UNION ALL
SELECT ',te,st,'  AS x UNION ALL
SELECT 'te,st'    AS x
) a

SELECT 
  x AS before
  ,SUBSTRING(x 
       ,LEN(x) - (LEN(LTRIM(REPLACE(x, '"', ' ')) + '|') - 1) + 1 --start_pos
       ,LEN(LTRIM(REPLACE(x, '"', ' '))) --length
       ) AS after
FROM 
(
SELECT 'test'     AS x UNION ALL
SELECT '"'        AS x UNION ALL
SELECT '"test'    AS x UNION ALL
SELECT 'test"'    AS x UNION ALL
SELECT '"test"'   AS x UNION ALL
SELECT '""test'   AS x UNION ALL
SELECT 'test""'   AS x UNION ALL
SELECT '""test""' AS x UNION ALL
SELECT '"te"st"'  AS x UNION ALL
SELECT 'te"st'    AS x
) a