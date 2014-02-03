SELECT * FROM profile.person
WHERE person_ref = 637980

SELECT * FROM sys.columns

SELECT * FROM sys.tables


SELECT
  t.name AS table_name
  ,c.name AS col
  ,c.column_id
  ,CASE c.column_id WHEN 1 THEN '  ,' ELSE '  ' END
  + CASE c.system_type_id 
     WHEN 167 THEN 
       'REPLACE(SUBSTRING(' + c.name 
       + ', LENGTH(' + c.name 
       + ') - (LENGTH(LTRIM(REPLACE(' + c.name
       + ', '','', '' '')))) + 1'
       + ',LENGTH(TRIM(REPLACE(' + c.name 
       + ', '','', '' '')))), ''"'', '''''''') AS ' + c.name
    ELSE c.name  
    END AS x
FROM sys.columns c
  INNER JOIN sys.tables t ON c.object_id = t.object_id
  INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'profile'
ORDER BY t.name, c.column_id


SELECT a.system_type_id, a.name, COUNT(*) FROM (
SELECT
  t.name AS table_name
  ,c.name AS col
  ,c.column_id
  ,c.system_type_id
  ,ty.name
FROM sys.columns c
  INNER JOIN sys.tables t ON c.object_id = t.object_id
  INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
  INNER JOIN sys.types ty ON c.system_type_id = ty.system_type_id 
WHERE s.name = 'profile') a
GROUP BY a.system_type_id, a.name


SELECT * FROM profile.search_code
WHERE search_code_ref = 7344176