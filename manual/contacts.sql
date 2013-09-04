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
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Ref');    
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Title');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'First Name');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Last Name');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Client');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Job Title');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Telephone No');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Ext');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Fax No');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Mobile No');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Work Email');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Journal Notes');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Address Line 1');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Address Line 2');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Locality');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Town');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'County');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Postcode');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Country');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Location Search Codes');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'E-Shot');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Locations');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Job Category');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Industry');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Skills and Languages');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Status');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Owning Office');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Perm Consultant');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Contract Consultant');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Notes');
    INSERT INTO #p7m_meta VALUES('contacts_phase_1', 'Contact Role');
    
    INSERT INTO #p7m_meta
    SELECT 'contacts_link_to_job', cname FROM #p7m_meta
    UNION ALL
    SELECT 'contacts_client_visit', cname FROM #p7m_meta
    UNION ALL
    SELECT 'contacts_offer', cname FROM #p7m_meta;

-- Get valid Contacts
    SELECT
      per.person_ref
      ,CAST(NULL AS VARCHAR(255)) AS extract_type
    INTO #valid_contacts
    FROM person per
    WHERE EXISTS (SELECT 1 
                  FROM position pos
                  WHERE per.person_ref = pos.person_ref
                    AND pos.contact_status IS NOT NULL 
                    AND pos.record_status = 'C'); 
 
    UPDATE #valid_contacts 
    SET extract_type = 'contacts_offer'
    FROM #valid_contacts vc
      INNER JOIN event_role er ON vc.person_ref = er.person_ref
      INNER JOIN event e ON er.event_ref = e.event_ref
    WHERE e.type IN('F', 'H') 
      AND er.type IN('C1', 'C2')
      AND e.create_timestamp > DATEADD(MONTH, -24, GETDATE())
      AND EXISTS (SELECT 1
                  FROM event_role ru
                  WHERE ru.team IN(SELECT [value]
                                   FROM #p7m_vars WHERE [key] = 'teams')
                    AND ru.event_ref = er.event_ref);  
                    
    UPDATE #valid_contacts 
    SET extract_type = 'contacts_client_visit'
    FROM #valid_contacts vc
      INNER JOIN event_role er ON vc.person_ref = er.person_ref
      INNER JOIN event e ON er.event_ref = e.event_ref
    WHERE e.type = 'P14' 
      AND er.type IN('C1', 'C2')
      AND e.create_timestamp > DATEADD(MONTH, -6, GETDATE())
      AND EXISTS (SELECT 1
                  FROM event_role ru
                  WHERE ru.team IN(SELECT [value]
                                   FROM #p7m_vars WHERE [key] = 'teams')
                    AND ru.event_ref = er.event_ref);  
                    
--    UPDATE #valid_contacts
--    SET extract_type = 'contacts_link_to_job'
--    FROM #valid_contacts vc
--    WHERE EXISTS (SELECT 1
--                  FROM opportunity o
--                    INNER JOIN event e ON o.opportunity_ref = e.opportunity_ref
--                    INNER JOIN event_role er ON e.event_ref = er.event_ref
--                    INNER JOIN position pos ON er.person_ref = pos.person_ref
--                                          AND pos.contact_status IN('2','3','4','6')
--                  WHERE er.person_ref IS NOT NULL
--                    AND EXISTS (SELECT 1
--                                FROM event e
--                                WHERE e.type IN('K03','Q21')
--                                  AND e.opportunity_ref = o.opportunity_ref)
--                    AND er.type IN('C1','C2')
--                    AND o.responsible_team IN(SELECT [value]
--                                              FROM #p7m_vars WHERE [key] = 'teams')
--                    AND o.create_timestamp >= CAST('2012-10-01' AS DATETIME)
--                    AND vc.person_ref = er.person_ref);
                    
    UPDATE #valid_contacts
    SET extract_type = 'contacts_link_to_job'
    FROM #valid_contacts vc
    WHERE EXISTS (SELECT 1
                  FROM opportunity o
                    INNER JOIN opport_role r ON o.opportunity_ref = r.opportunity_ref
                    INNER JOIN position pos ON r.person_ref = pos.person_ref
                                           AND pos.contact_status IS NOT NULL
                                           AND pos.record_status ='C'
                  WHERE r.person_ref IS NOT NULL
--                    AND EXISTS (SELECT 1
--                                FROM event e
--                                WHERE e.type IN('K03','Q21')
--                                  AND e.opportunity_ref = o.opportunity_ref)
                    AND r.role_type IN('C1', 'C2', 'C6')
                    AND o.responsible_team IN(SELECT [value]
                                              FROM #p7m_vars WHERE [key] = 'teams')
                    AND o.create_timestamp >= CAST('2012-10-01' AS DATETIME)
                    AND r.person_ref = vc.person_ref);
                    
    UPDATE #valid_contacts
    SET extract_type = 'contacts_phase_1'
    FROM #valid_contacts vc
    WHERE EXISTS (SELECT 1
                  FROM opport_role r
                    INNER JOIN opportunity o ON r.opportunity_ref = o.opportunity_ref
                  WHERE vc.person_ref = r.person_ref
                    AND o.responsible_team IN(SELECT [value]
                                              FROM #p7m_vars WHERE [key] = 'teams')
                    AND o.record_status IN('L', 'L1')
                    AND r.role_type IN('C1', 'C2', 'C6'));
                    
    DELETE FROM #valid_contacts 
    WHERE extract_type IS NULL; 
    
-- Load contacts phase 1
SET sql_cmd = '
SELECT
  [Ref]
  ,[Title]
  ,[First Name]
  ,[Last Name]
  ,[Client]
  ,[Job Title]
  ,[Telephone No]
  ,[Ext]
  ,[Fax No]
  ,[Mobile No]
  ,[Work Email]
  ,[Journal Notes]
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Postcode]
  ,[Country]
  ,LIST(CASE WHEN code_type = 1015 THEN code_description END, ''; '') AS [Location Search Codes]
  ,[E-Shot]
  ,LIST(CASE WHEN code_type = 1015 THEN code_description END, ''; '') AS [Locations]
  ,LIST(CASE WHEN code_type = 1000 THEN code_description END, ''; '') AS [Job Category]
  ,LIST(CASE WHEN code_type = 1005 THEN code_description END, ''; '') AS [Industry]
  ,LIST(CASE WHEN code_type IN(1007, 1010, 1011, 1012,
                               1014, 1016, 1017, 1018, 1055) 
             THEN code_description END, ''; '') AS [Skills and Languages]
  ,[Status]
  ,CASE WHEN MAX(pt_person_ref) IS NOT NULL THEN MAX(s_team)
        WHEN MAX(teams_value) IS NULL THEN NULL
        ELSE responsible_team END AS [Owning Office]
  ,CASE WHEN MAX(pt_person_ref) IS NOT NULL THEN MAX(sp_displayname)
        WHEN MAX(teams_value) IS NULL THEN NULL
        ELSE displayname END AS [Perm Consultant]
  ,CASE WHEN MAX(pt_person_ref) IS NOT NULL THEN MAX(sp_displayname)
        WHEN MAX(teams_value) IS NULL THEN NULL
        ELSE displayname END AS [Contract Consultant]
  ,[Notes]
  ,LIST(CASE WHEN code_type = 1045 THEN code_description END, ''; '') AS [Contact Role]
INTO #p7m_#table
FROM (
SELECT DISTINCT
  per.person_ref AS [Ref]
  ,per.title AS [Title]
  ,per.first_name AS [First Name]
  ,per.Last_name AS [Last Name]
  ,org.displayname AS [Client]
  ,pos.displayname AS [Job Title]
  ,ISNULL(pos.telephone_number, a.telephone_number) AS [Telephone No]
  ,pos.telephone_ext AS [Ext]
  ,pos.fax_number AS [Fax No]
  ,pos.mobile_telno AS [Mobile No]
  ,pos.email_address AS [Work Email]
  ,CAST(per.person_ref AS VARCHAR) + '' - P7 Contact Ref'' AS [Journal Notes]
  ,a.address_line_1 AS [Address Line 1]
  ,a.address_line_2 AS [Address Line 2]
  ,a.address_line_3 AS [Locality]
  ,a.post_town AS [Town]
  ,a.county_state AS [County]
  ,ISNULL(''="'' + a.zipcode + ''"'', '''') AS [Postcode]
  ,c.description AS [Country]
  ,CASE pos.do_not_mailshot WHEN ''Y'' THEN ''No'' ELSE ''Yes'' END AS [E-Shot]
  ,stat.description AS [Status]
  ,pos.responsible_team
  ,ru.displayname
  ,REPLACE(REPLACE(pos.notes, ''\x0d'', ''''), ''\x0a'', '''') AS [Notes]
  ,sc.code_type
  ,l.description AS code_description
  ,s.team AS s_team
  ,pt.person_ref AS pt_person_ref
  ,teams.[value] AS teams_value
  ,sp.displayname AS sp_displayname
FROM person per
  INNER JOIN position pos ON per.person_ref = pos.person_ref
  LEFT OUTER JOIN organisation org ON pos.organisation_ref = org.organisation_ref
  LEFT OUTER JOIN lookup stat ON pos.record_status = stat.code AND stat.code_type = 132
  LEFT OUTER JOIN person ru ON pos.responsible_user = ru.person_ref
  LEFT OUTER JOIN address a ON pos.address_ref = a.address_ref
  LEFT OUTER JOIN lookup c ON a.country_code = c.code AND c.code_type = 100
  LEFT OUTER JOIN search_code sc ON per.person_ref = sc.person_ref 
     AND pos.position_ref = sc.position_ref
     AND sc.code_type IN(1000, 1005, 1015, 1007, 1010, 1011, 1012,
                         1014, 1016, 1017, 1018, 1055, 1045)
     AND sc.search_type = 4
  LEFT OUTER JOIN lookup l ON sc.code_type = l.code_type AND sc.code = l.code
  LEFT OUTER JOIN staff s ON sc.code = s.resp_user_code
                         AND sc.code_type = 1055
                         AND s.team IN(SELECT [value] 
                                       FROM #p7m_vars tkc_teams WHERE [key] = ''teams'')
  LEFT OUTER JOIN person_type pt ON s.person_type_ref = pt.person_type_ref 
                                AND pt.type LIKE ''Z%''
  LEFT OUTER JOIN person sp ON sp.person_ref = pt.person_ref 
  LEFT OUTER JOIN #p7m_vars teams
               ON pos.responsible_team = teams.[value] AND teams.[key] = ''teams'' 
WHERE EXISTS (SELECT 1
              FROM #valid_contacts 
              WHERE extract_type = ''#table''
                AND person_ref = per.person_ref)
  AND pos.contact_status IS NOT NULL 
  AND pos.record_status = ''C''

) a
GROUP BY
  [Ref]
  ,[Title]
  ,[First Name]
  ,[Last Name]
  ,[Client]
  ,[Job Title]
  ,[Telephone No]
  ,[Ext]
  ,[Fax No]
  ,[Mobile No]
  ,[Work Email]
  ,[Journal Notes]
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Postcode]
  ,[Country]
  ,[E-Shot]
  ,[Status]
  ,responsible_team
  ,displayname
  ,[Notes]';

    EXECUTE (REPLACE(sql_cmd, '#table', 'contacts_phase_1'));
    
    EXECUTE (REPLACE(sql_cmd, '#table', 'contacts_link_to_job'));

    EXECUTE (REPLACE(sql_cmd, '#table', 'contacts_client_visit'));

    EXECUTE (REPLACE(sql_cmd, '#table', 'contacts_offer'));
   
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
