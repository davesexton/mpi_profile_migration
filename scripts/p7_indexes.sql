DELETE FROM valid_clients
WHERE id = 53


SELECT * FROM OPENQUERY(P7UKMPDEV, '

SELECT o.name AS obj_name,
       i.name AS idx_name
  FROM sysobject o
  INNER JOIN sysindex i
    ON (o.id = i.id)
')

ALTER TABLE Persons
ADD PRIMARY KEY (P_Id)

SELECT
  'ALTER TABLE profile.' + table_name 
  + ' ADD PRIMARY KEY (' + table_name + '_ref)' AS prim_key
  ,'TRUNCATE TABLE profile.' + table_name AS trunc_cmd
  ,'CREATE '
  + CASE [unique] WHEN 'Y' THEN 'UNIQUE ' ELSE '' END
  + 'INDEX '
  + index_name
  + ' ON profile.' + table_name 
  + '(' + CAST([columns] AS VARCHAR(400))
  + ');'
  AS sql_cmd
  ,* 
FROM OPENQUERY(P7UKMPDEV, '

SELECT
  t.table_name
  ,i.index_id
  ,i.index_name
  ,i.[unique]
  ,LIST(''['' || c.column_name || 
   ''] '' ||
   (CASE [order] WHEN ''A'' THEN ''Asc'' ELSE ''Desc'' END), '', '') AS [columns]
FROM sysixcol tic
  INNER JOIN systable t ON tic.table_id = t.table_id
  INNER JOIN sysindex i ON tic.index_id = i.index_id
                       AND tic.table_id = i.table_id
  INNER JOIN syscolumn c ON tic.column_id = c.column_id
                        AND tic.table_id = c.table_id
WHERE table_name IN(''address'', ''candidate'',''event'',''event_role'',
                    ''lookup'',''opport_role'',''opportunity'',
                    ''organisation'',''permanent_emp'',''permanent_vac'',
                    ''person'',''person_type'',''placing'',''position'',
                    ''search_code'',''staff'',''temporary_booking'',
                    ''temporary_emp'',''temporary_vac'',''u_v5invoice'')
GROUP BY
  t.table_name
  ,i.index_id
  ,i.index_name
  ,i.[unique]
                    
')
ORDER BY table_name, index_name


SELECT * FROM OPENQUERY(P7UKMPDEV, '

SELECT *
FROM systypes
')


SELECT * FROM OPENQUERY(P7UKMPDEV, '
SELECT *
FROM sysixcol
')


SELECT * FROM OPENQUERY(P7UKMPDEV, '
SELECT 
  t.table_name
  ,c.*
FROM syscolumn c
  INNER JOIN systable t ON c.table_id = t.table_id
WHERE width IN(1)
  AND t.table_name NOT LIKE ''SYS%''
  AND t.table_name NOT LIKE ''jdbc%''
  AND t.table_name NOT LIKE ''spt%''
')