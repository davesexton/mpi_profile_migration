BEGIN
  DECLARE var_text VARCHAR(8000);

  SET var_text = '
csv_file_path=C:\Documents and Settings\davesexton\Desktop\temp\chicago_
teams=BKCH
teams=CMCH
teams=CMIC
teams=MSCH
teams=PSCH
';

  BEGIN
-- Create variables
    DECLARE csv_file_path VARCHAR(255);
    DECLARE sql_cmd VARCHAR(8000);

-- Create tables
    CREATE TABLE #p7m_vars
    (
      [key] VARCHAR(255)
      ,[value] VARCHAR(255)
    );

    CREATE TABLE #p7m_meta
    (
      tname VARCHAR(255)
      ,cname VARCHAR(255)
    );

-- Load vars table
    BEGIN
      DECLARE pos INT;
      DECLARE k VARCHAR(255);
      DECLARE v VARCHAR(255);
      WHILE CHARINDEX(CHAR(10), var_text) > 0 LOOP
        SET pos = CHARINDEX(CHAR(10), var_text);
        SET k = SUBSTRING(var_text, 1, pos - 1);
        SET v = TRIM(SUBSTRING(k, CHARINDEX('=', k) + 1));
        SET k = TRIM(SUBSTRING(k, 1, CHARINDEX('=', k) - 1));
        INSERT INTO #p7m_vars VALUES(k, v);
        SET var_text = SUBSTRING(var_text, pos + 1);
      END LOOP;
    END;

-- Get CSV path
    SELECT MAX([value])
    INTO csv_file_path
    FROM #p7m_vars WHERE [key] = 'csv_file_path';

-- Insert meta records
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Ref');    
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Client Name');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Address Line 1');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Address Line 2');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Locality');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Town');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'County');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Postcode');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Country');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Location Search Codes');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Journal Notes');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Client Type');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Telephone No');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Website');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Client Source');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Year End Date');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Record Status');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Sector Search Codes');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Fax No');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Consultant Notes');
--    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Discipline Search Codes');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Perm Consultant');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Con Consultant');
    INSERT INTO #p7m_meta VALUES('clients_phase_1', 'Owning Team');
    
    INSERT INTO #p7m_meta
    SELECT 'clients_link_to_job', cname FROM #p7m_meta
    UNION ALL
    SELECT 'clients_client_visit', cname FROM #p7m_meta
    UNION ALL
    SELECT 'clients_offer', cname FROM #p7m_meta;
    
-- Get valid Clients
    SELECT
      org.organisation_ref
      ,CAST(NULL AS VARCHAR(255)) AS extract_type
    INTO #valid_clients
    FROM organisation org
    WHERE org.record_status != 'Y'; 

    UPDATE #valid_clients
    SET extract_type = 'clients_offer'
    FROM #valid_clients vc    
    WHERE EXISTS (SELECT 1
                  FROM event e
                    INNER JOIN event_role er ON e.event_ref = er.event_ref
                  WHERE e.type IN('F', 'H')
                    AND e.organisation_ref IS NOT NULL
                    AND EXISTS (SELECT 1
                                FROM event_role ru
                                WHERE ru.team IN(SELECT [value]
                                                 FROM #p7m_vars 
                                                 WHERE [key] = 'teams')
                                  AND ru.event_ref = er.event_ref)
                    AND e.create_timestamp > DATEADD(MONTH, -24, GETDATE())
                    AND vc.organisation_ref = e.organisation_ref);
    
    UPDATE #valid_clients
    SET extract_type = 'clients_client_visit'
    FROM #valid_clients vc    
    WHERE EXISTS (SELECT 1
                  FROM event e
                    INNER JOIN event_role er ON e.event_ref = er.event_ref
                  WHERE e.type ='P14'
                    AND e.organisation_ref IS NOT NULL
                    AND EXISTS (SELECT 1
                                FROM event_role ru
                                WHERE ru.team IN(SELECT [value]
                                                 FROM #p7m_vars WHERE [key] = 'teams')
                    AND e.create_timestamp > DATEADD(MONTH, -6, GETDATE())
                    AND ru.event_ref = er.event_ref)
                    AND vc.organisation_ref = e.organisation_ref);
    
    UPDATE #valid_clients
    SET extract_type = 'clients_link_to_job'
    FROM #valid_clients vc
    WHERE EXISTS (SELECT 1
                  FROM opportunity opp
                  WHERE opp.responsible_team IN(SELECT [value]
                                                FROM #p7m_vars WHERE [key] = 'teams')
                    AND opp.create_timestamp >= CAST('2012-10-01' AS DATETIME)
                    AND vc.organisation_ref = opp.organisation_ref);
    
    UPDATE #valid_clients
    SET extract_type = 'clients_phase_1'
    FROM #valid_clients vc
    WHERE EXISTS (SELECT 1 
                  FROM opportunity opp 
                  WHERE vc.organisation_ref = opp.organisation_ref
                    AND opp.record_status IN('L', 'L1')
                    AND opp.responsible_team IN(SELECT [value]
                                                FROM #p7m_vars WHERE [key] = 'teams'));
    
    DELETE FROM #valid_clients 
    WHERE extract_type IS NULL;

-- Load clients phase 1
SET sql_cmd = '
SELECT
  [Ref]
  ,[Client Name]
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Postcode]
  ,[Country]
  ,LIST(CASE WHEN code_type = 1015 THEN code_description END, ''; '') AS [Location Search Codes]
  ,[Journal Notes]
  ,[Client Type]
  ,[Telephone No]
  ,[Website]
  ,[Client Source]
  ,[Year End Date]
  ,[Record Status]
  ,LIST(CASE WHEN code_type = 1005 THEN code_description END, ''; '') AS [Sector Search Codes]
  ,[Fax No]
  ,[Consultant Notes]
--  ,LIST(CASE WHEN code_type = 1000 THEN code_description END, ''; '') AS [Discipline Search Codes]
  ,[Perm Consultant]
  ,[Con Consultant]
  ,[Owning Team]
INTO #p7m_#table
FROM (
  SELECT DISTINCT
    o.organisation_ref AS [Ref]
    ,o.name AS [Client Name]
    ,a.address_line_1 AS [Address Line 1]
    ,a.address_line_2 AS [Address Line 2]    
    ,a.address_line_3 AS [Locality]
    ,a.post_town AS [Town]  
    ,a.county_state AS [County]
    ,ISNULL(''="'' + a.zipcode + ''"'', '''') AS [Postcode]  
    ,c.description AS [Country]
    ,CAST(o.organisation_ref AS VARCHAR) + '' - P7 Org Ref'' AS [Journal Notes]
    ,CASE o.type WHEN ''G'' THEN ''Head office''
                 WHEN ''S'' THEN ''Subsidiary''
                 WHEN ''Z'' THEN ''Sites''
                 WHEN ''L'' THEN ''Head office''
                 ELSE ''Subsidiary''
                 END AS [Client Type]
    ,a.telephone_number AS [Telephone No]
    ,o.web_site_url AS [Website]
    ,src.description AS [Client Source]
    ,o.financial_year_end AS [Year End Date] 
    ,CASE o.record_status WHEN ''Z'' THEN ''Incomplete''
                          WHEN ''D'' THEN ''Inactive''
                          WHEN ''L'' THEN ''Active''
                          ELSE ''''
                          END AS [Record Status]
    ,a.fax_number AS [Fax No]
    ,REPLACE(REPLACE(o.notes, ''\x0d'', ''''), ''\x0a'', '''') AS [Consultant Notes]
    ,per.displayname AS [Perm Consultant]
    ,per.displayname AS [Con Consultant]
    ,o.responsible_team AS [Owning Team]
    ,sc.code_type
    ,sc.code
    ,l.description AS code_description
  FROM organisation o
    LEFT OUTER JOIN person per ON o.responsible_user = per.person_ref 
    LEFT OUTER JOIN address a ON o.organisation_ref = a.organisation_ref
        AND a.create_timestamp = (SELECT ISNULL(MAX(CASE main_address WHEN ''Y'' 
                                                                      THEN create_timestamp 
                                                                      END)
                                               ,MAX(create_timestamp))
                                  FROM address a1
                                  WHERE a.organisation_ref = a1.organisation_ref)
    LEFT OUTER JOIN lookup c ON a.country_code = c.code AND c.code_type = 100
    LEFT OUTER JOIN lookup src ON o.source = src.code AND src.code_type = 108
    LEFT OUTER JOIN search_code sc ON o.organisation_ref = sc.organisation_ref 
      AND sc.code_type IN(1000, 1005, 1015)
      AND sc.search_type = 3
    LEFT OUTER JOIN lookup l ON sc.code_type = l.code_type AND sc.code = l.code
  WHERE EXISTS (SELECT 1
                FROM #valid_clients 
                WHERE extract_type = ''#table''
                  AND organisation_ref = o.organisation_ref)
   AND o.record_status != ''Y'' 
) a
GROUP BY
  [Ref]
  ,[Client Name]
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Postcode]
  ,[Country]
  ,[Journal Notes]
  ,[Client Type]
  ,[Telephone No]
  ,[Website]
  ,[Client Source]
  ,[Year End Date]
  ,[Record Status]
  ,[Fax No]
  ,[Consultant Notes]
  ,[Perm Consultant]
  ,[Con Consultant]
  ,[Owning Team]';

    EXECUTE (REPLACE(sql_cmd, '#table', 'clients_phase_1') );

    EXECUTE (REPLACE(sql_cmd, '#table', 'clients_link_to_job') );

    EXECUTE (REPLACE(sql_cmd, '#table', 'clients_client_visit') );

    EXECUTE (REPLACE(sql_cmd, '#table', 'clients_offer') );
    
-- Output CSV files
    BEGIN
      DECLARE v_csv VARCHAR(8000);
      DECLARE c_csv CURSOR FOR
         SELECT
          'UNLOAD SELECT ''"' || LIST(cname, '","') || '"'''
          || ' UNION ALL SELECT ''"''||REPLACE(TRIM(['
          || LIST(cname, ']),''"'',''""'')||''","''||REPLACE(TRIM([')
          || ']),''"'',''""'')||''"'''
          || ' FROM #p7m_' || tname
          || ' TO ''' || csv_file_path || tname || '.csv'' FORMAT ASCII QUOTES off ESCAPES off'
        FROM #p7m_meta
        GROUP BY
          tname;
     OPEN c_csv;
      FETCH c_csv INTO v_csv;
      WHILE SQLCODE = 0 LOOP
        EXECUTE (v_csv);
        FETCH c_csv INTO v_csv;
      END LOOP;
      CLOSE c_csv;
      DEALLOCATE c_csv;
    END;

  END;
END;
