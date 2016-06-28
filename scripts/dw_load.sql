CREATE PROCEDURE [migration].[dw_load_table] @linked_server VARCHAR(255), @table_name VARCHAR(255)  
AS
DECLARE @sql VARCHAR(4000)
DECLARE @select_list VARCHAR(MAX)
DECLARE @create_list VARCHAR(MAX)
DECLARE @result TABLE (select_list VARCHAR(MAX), create_list VARCHAR(MAX))
DECLARE @import_count INT

PRINT 'Loading: ' + @table_name

SET @sql = '
SELECT *
FROM OPENQUERY([' + @linked_server + '],''
  SELECT
    LIST(select_fld,'''','''') AS select_list
    ,LIST(create_fld,'''','''') AS create_list
  FROM (
  SELECT 
    --c.column_name AS select_fld
    CASE WHEN domain_name LIKE ''''%date%'''' OR domain_name LIKE ''''%time%''''
         THEN ''''CAST('''' + c.column_name + '''' AS VARCHAR)''''
         ELSE c.column_name END AS select_fld
    ,c.column_name
      + '''' ''''
      + CASE WHEN domain_name LIKE ''''%char%'''' 
             THEN ''''VARCHAR('''' + CAST(width AS VARCHAR) + '''')'''' 
             WHEN domain_name LIKE ''''%date%'''' 
             THEN ''''DATETIME2''''
             WHEN domain_name LIKE ''''%time%'''' 
             THEN ''''DATETIME2''''
             WHEN domain_name LIKE ''''%int%'''' 
             THEN ''''INT''''
             WHEN scale != 0 
             THEN ''''DECIMAL('''' + CAST(width AS VARCHAR) + '''','''' + CAST(scale AS VARCHAR) + '''')''''
             ELSE '''' '''' END 
      + CASE nulls WHEN ''''N'''' THEN '''' NOT NULL'''' ELSE '''''''' END
     AS create_fld
  FROM syscolumn c
    INNER JOIN systable t ON c.table_id = t.table_id
    INNER JOIN sysdomain d ON c.domain_id = d.domain_id
  WHERE domain_name NOT LIKE ''''%binary%''''
    AND SUBSTR(c.column_name, 1, 2) != ''''z_''''
    AND SUBSTR(c.column_name, 1, 3) != ''''zc_''''
    AND SUBSTR(c.column_name, 1, 4) != ''''vat_''''
    AND SUBSTR(c.column_name, 1, 5) NOT IN(''''grid_'''',''''enri_'''')
    AND SUBSTR(c.column_name, 1, 6) NOT IN(''''block_'''',''''to_do_'''',
        ''''rate2_'''',''''rate3_'''',''''rate4_'''')
    AND SUBSTR(c.column_name, 1, 7) != ''''profit_''''
    AND SUBSTR(c.column_name, 1, 11) != ''''compliance_''''
    AND c.column_name NOT IN(''''user_date2'''',''''user_date3'''',''''user_date4'''')
    AND c.column_name NOT LIKE ''''%key''''
    AND c.column_name NOT LIKE ''''user_number%''''
    AND c.column_name NOT LIKE ''''user_text%''''
    AND c.column_name NOT LIKE ''''user_user%''''
    AND c.column_name != ''''xexternal_ref''''
    AND c.column_name != ''''lock_user''''
    AND c.column_name != ''''function''''
    AND c.column_name != ''''custom_cols_start''''
    AND table_name = ''''' + @table_name + '''''
    ) a
 '')
 '
 
INSERT INTO @result EXEC(@sql)
 
SELECT 
  @select_list = select_list
  ,@create_list = create_list 
FROM @result

IF OBJECT_ID(@table_name + '1', N'U') IS NOT NULL
  EXEC('DROP TABLE [' + @table_name + '1]')
      
EXEC
(
  'CREATE TABLE [dbo].[' + @table_name + '1] ('
  + @create_list
  + ', CONSTRAINT [pk_'
  + @table_name
  + '_ref1] PRIMARY KEY CLUSTERED ('
  + @table_name
  + '_ref ASC)'
  + ')'
)
   
EXEC
(
  'INSERT INTO [dbo].[' + @table_name + '1] '
  + ' SELECT * FROM OPENQUERY(['
  + @linked_server
  + '], '''
  + 'SELECT '
  + @select_list
  + ' FROM '
  + @table_name
  + ' ORDER BY '
  + @table_name
  + '_ref ASC'
  + ''')'
)

SET @import_count = @@ROWCOUNT

INSERT INTO migration.dw_import_log 
(
	import_timestamp
	,import_sp
	,import_count
)
VALUES(GETDATE(), @table_name, @import_count)

PRINT CAST(SYSDATETIME() AS VARCHAR(19)) + ' ' + @table_name + ': ' + CAST(@import_count AS VARCHAR) + ' loaded' 
    
IF OBJECT_ID(@table_name, N'U') IS NOT NULL
  EXEC('DROP TABLE [' + @table_name + ']')

EXEC('sp_rename ''dbo.' + @table_name + '1'',''' + @table_name + '''')
EXEC('sp_rename ''dbo.' + @table_name + '.pk_' + @table_name + '_ref1'',''pk_' + @table_name + '_ref'', ''index''')


GO

----------------------------------------------------------------------------------------------
CREATE TABLE [migration].[dw_import_log](
	[import_timestamp] [datetime] NOT NULL,
	[import_sp] [varchar](50) NOT NULL,
	[import_count] [int] NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


----------------------------------------------------------------------------------------------
CREATE PROCEDURE [migration].[dw_load] @linked_server_name VARCHAR(255)  
AS

EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'address'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'candidate'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'event'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'event_role'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'linkfile'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'lookup'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'opport_role'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'opportunity'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'organisation'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'permanent_emp'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'permanent_vac'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'person'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'person_type'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'placing'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'position'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'search_code'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'staff'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'temporary_booking'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'temporary_emp'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'temporary_vac'
EXEC migration.dw_load_table @linked_server = @linked_server_name, @table_name = 'u_v5invoice'


GO

