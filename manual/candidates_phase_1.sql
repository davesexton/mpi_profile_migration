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
    DECLARE sql_start VARCHAR(8000);
    DECLARE sql_where VARCHAR(8000);
    DECLARE sql_end VARCHAR(8000);
    
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
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Ref');  
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Title');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'First Name');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Last Name');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Email');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Address Line 1');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Address Line 2');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Locality');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Town');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'County');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Postcode');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Country');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Locations');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Home');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Work');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Ext.');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Mobile');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Source');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Contract');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Perm');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Default View');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Journal Notes');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Initials');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Email (W)');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'E-Shot');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Owning Office');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Perm Consultant');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Contract Consultant');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Status Perm');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Status Contract');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Skills and Languages');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Industry Sectors');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Qualifications');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Job Category');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Minimum Salary');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Minimum Rate');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Willing to relocate');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Prefered Locations');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Hot Candidate');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Visa Expiry');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Visa Type');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'CV Received');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Part Time');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Highest Education Level');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Own Transport');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Exclusive');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Preferences, Experinces, Personal Attributes');
    INSERT INTO #p7m_meta VALUES('candidates_phase_1', 'Work History Link');
    
    INSERT INTO #p7m_meta
    SELECT 'candidates_reg_int', cname FROM #p7m_meta
    UNION ALL 
    SELECT 'candidates_off_2y', cname FROM #p7m_meta;

-- Load candidates phase 1
SET sql_start = '
SELECT 
  [Ref]
  ,[Title]
  ,[First Name]
  ,[Last Name]
  ,[Email]
  ,[Address Line 1]
  ,[Address Line 2]    
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Postcode]
  ,[Country]
  ,LIST(CASE WHEN code_type = 1015 THEN code_description END, ''; '') AS [Locations]
  ,[Home]
  ,[Work]
  ,[Ext.]
  ,[Mobile]
  ,[Source]
  ,[Contract]
  ,[Perm]
  ,[Default View]
  ,[Journal Notes]
  ,[Initials]
  ,[Email (W)]
  ,[E-Shot]
  ,CASE WHEN MAX(pt_person_ref) IS NOT NULL THEN MAX(s_team)
        WHEN MAX(teams_value) IS NULL THEN NULL
        ELSE responsible_team END AS [Owning Office]
  ,CASE WHEN MAX(pt_person_ref) IS NOT NULL THEN MAX(sp_displayname)
        WHEN MAX(teams_value) IS NULL THEN NULL
        ELSE displayname END AS [Perm Consultant]
  ,CASE WHEN MAX(pt_person_ref) IS NOT NULL THEN MAX(sp_displayname)
        WHEN MAX(teams_value) IS NULL THEN NULL
        ELSE displayname END AS [Contract Consultant]
  ,[Status Perm]
  ,[Status Contract]
  ,LIST(CASE WHEN code_type IN(1008, 1036, 1039, 1041, 1030, 
                               1007, 1010, 1011, 1012, 1014, 1016, 1017, 1018) 
             THEN code_description END, ''; '') AS [Skills and Languages]
  ,LIST(CASE WHEN code_type = 1005 
             THEN code_description END, ''; '') AS [Industry Sectors]
  ,date_of_birth + ''; ''
    + LIST(CASE WHEN code_type IN(1025, 1020) 
                THEN code_description END, ''; '') AS [Qualifications]
  ,LIST(CASE WHEN code_type = 1000 THEN code_description END, ''; '') AS [Job Category]
  ,[Minimum Salary]
  ,[Minimum Rate]
  ,[Willing to relocate]
  ,LIST(CASE WHEN code_type = 1015 
             THEN code_description END, ''; '') AS [Prefered Locations]
  ,LIST(CASE WHEN code_type = 2080 AND code = ''01'' 
             THEN code_description END, ''; '') AS [Hot Candidate]
  ,[Visa Expiry]
  ,[Visa Type]
  ,[CV Received]
  ,[Part Time]
  ,LIST(CASE WHEN code_type = 1020 
             THEN code_description END, ''; '') AS [Highest Education Level]
  ,[Own Transport]
  ,[Exclusive]
  ,[Preferences, Experinces, Personal Attributes]
  ,[Work History Link]
INTO #table
FROM (
SELECT DISTINCT
  per.person_ref AS ref
  ,per.title AS [Title]
  ,per.first_name AS [First Name]
  ,per.Last_name AS [Last Name]
  ,per.email_address AS [Email]
  ,a.address_line_1 AS [Address Line 1]
  ,a.address_line_2 AS [Address Line 2]    
  ,a.address_line_3 AS [Locality]
  ,a.post_town AS [Town]  
  ,a.county_state AS [County]
  ,ISNULL(''="'' + a.zipcode + ''"'', '''') AS [Postcode]
  ,c.description AS [Country]
  ,ISNULL(''="'' + a.telephone_number + ''"'', '''') AS [Home]
  ,ISNULL(''="'' + pos.telephone_number + ''"'', '''') AS [Work]
  ,ISNULL(''="'' + pos.telephone_ext + ''"'', '''') AS [Ext.]
  ,ISNULL(''="'' + per.mobile_telno + ''"'', '''') AS [Mobile]
  ,src.description AS [Source]
  ,CASE WHEN ptc.person_ref IS NOT NULL THEN ''Yes'' END AS [Contract]
  ,CASE WHEN ptp.person_ref IS NOT NULL THEN ''Yes'' END AS [Perm]
  ,CASE WHEN ptp.person_ref IS NOT NULL THEN ''Perm'' ELSE ''Contract'' END AS [Default View]
  ,CAST(per.person_ref AS VARCHAR) + '' - P7 Cand Ref'' AS [Journal Notes]
  ,per.initials AS [Initials]
  ,pos.email_address AS [Email (W)]
  ,CASE per.do_not_mailshot WHEN ''Y'' THEN ''No'' ELSE ''Yes'' END AS [E-Shot]
  ,ru.responsible_team
  ,ru.displayname
  ,statp.description AS [Status Perm]
  ,statc.description AS [Status Contract]
  ,CAST(canp.income_required AS VARCHAR) AS [Minimum Salary]
  ,CAST(canc.income_required AS VARCHAR) AS [Minimum Rate]
  ,per.discretion_reqd AS [Willing to relocate]
  ,CAST(per.user_date1 AS VARCHAR) AS [Visa Expiry]
  ,per.nationality AS [Visa Type]
  ,CAST(per.cv_last_updated AS VARCHAR) AS [CV Received]
  ,CASE WHEN COALESCE(canp.part_time, canc.part_time) = ''Y'' THEN ''Yes'' END AS [Part Time]
  ,CASE per.own_car WHEN ''Y'' THEN ''Yes'' END AS [Own Transport]
  ,CASE per.sole_agency WHEN ''Y'' THEN ''Yes'' END AS [Exclusive]
  ,REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(ISNULL(a.notes, '''') + '' '' 
     + ISNULL(ptp.notes, '''') + '' '' 
     + ISNULL(ptc.notes, '''')), ''  '', '' ''), ''\x0d'', ''''), ''\x0a'', ''''), ''='', '''') AS [Preferences, Experinces, Personal Attributes]
  ,CAST(pos.person_ref AS VARCHAR) AS [Work History Link]
  ,sc.code_type
  ,sc.code
  ,l.description AS code_description
  ,CAST(per.date_of_birth AS VARCHAR) AS date_of_birth
  ,s.team AS s_team
  ,pt.person_ref AS pt_person_ref
  ,teams.[value] AS teams_value
  ,sp.displayname AS sp_displayname
FROM person per
  LEFT OUTER JOIN person_type ptp ON per.person_ref = ptp.person_ref AND ptp.type = ''C''
  LEFT OUTER JOIN person_type ptc ON per.person_ref = ptc.person_ref AND ptc.type = ''A''
  LEFT OUTER JOIN candidate canp ON ptp.person_type_ref = canp.person_type_ref
  LEFT OUTER JOIN candidate canc ON ptc.person_type_ref = canc.person_type_ref
  LEFT OUTER JOIN lookup statp ON ptp.status = statp.code AND statp.code_type = 105
  LEFT OUTER JOIN lookup statc ON ptc.status = statc.code AND statc.code_type = 105
  LEFT OUTER JOIN address a ON per.person_ref = a.person_ref
    AND a.create_timestamp = (SELECT ISNULL(MAX(CASE main_address WHEN ''Y'' 
                                                                  THEN create_timestamp 
                                                                  END)
                                ,MAX(create_timestamp))
                              FROM address a1
                              WHERE a.person_ref = a1.person_ref)
  LEFT OUTER JOIN search_code sc ON per.person_ref = sc.person_ref 
     AND sc.code_type IN(1015, 1020, 1025, 1020, 1008, 1036, 1039, 1041, 1030,
                         1007, 1010, 1011, 1012, 1014, 1016, 1017, 1018, 1005,
                         1025, 1020, 1000, 2080,
                         1055)
     AND sc.search_type = 1
  LEFT OUTER JOIN lookup l ON sc.code_type = l.code_type AND sc.code = l.code
  LEFT OUTER JOIN lookup src ON per.source = src.code AND src.code_type = 102
  LEFT OUTER JOIN lookup c ON a.country_code = c.code AND c.code_type = 100
  LEFT OUTER JOIN position pos ON per.person_ref = pos.person_ref 
    AND COALESCE(pos.start_date, pos.end_date, pos.create_timestamp) 
      = (SELECT MAX(COALESCE(start_date, end_date, create_timestamp))
         FROM position pos_last
         WHERE pos.person_ref = pos_last.person_ref)
  LEFT OUTER JOIN person ru ON per.responsible_user = ru.person_ref
  LEFT OUTER JOIN staff s ON sc.code = s.resp_user_code
                         AND sc.code_type = 1055
                         AND s.team IN(SELECT [value] 
                                       FROM #p7m_vars tkc_teams WHERE [key] = ''teams'')
  LEFT OUTER JOIN person_type pt ON s.person_type_ref = pt.person_type_ref 
                                AND pt.type LIKE ''Z%''
  LEFT OUTER JOIN person sp ON sp.person_ref = pt.person_ref 
  LEFT OUTER JOIN #p7m_vars teams
               ON pos.responsible_team = teams.[value] AND teams.[key] = ''teams''';
SET sql_where = '
WHERE EXISTS (SELECT 1
              FROM person_type pts
              WHERE pts.type IN(''A'', ''C'')
                AND per.person_ref = pts.person_ref
                AND EXISTS(SELECT 1
                           FROM event_role er
                             INNER JOIN event e ON er.event_ref = e.event_ref
                             INNER JOIN opportunity o ON e.opportunity_ref = o.opportunity_ref
                           WHERE er.type IN(''D'', ''K'', ''1'', ''A1'', ''I'', ''H'', ''F'', ''G1'')
                             AND o.responsible_team IN(SELECT [value]
                                                       FROM #p7m_vars WHERE [key] = ''teams'')
                             AND o.record_status IN(''L'', ''L1'')
                             AND pts.person_ref = er.person_ref))';
SET sql_end = '
) a
GROUP BY
  [ref]
  ,[Title]
  ,[First Name]
  ,[Last Name]
  ,[Contract]
  ,[Perm]
  ,[Default View]
  ,[Email]
  ,[Address Line 1]
  ,[Address Line 2]    
  ,[Locality]
  ,[Town]  
  ,[County]
  ,[Postcode]
  ,[Country]
  ,[Home]
  ,[Work]
  ,[Ext.]
  ,[Mobile]
  ,[Source]
  ,[Journal Notes]
  ,[Initials]
  ,[Email (W)]
  ,[E-Shot]
  ,responsible_team
  ,displayname
  ,[Status Perm]
  ,[Status Contract]
  ,[Minimum Salary]
  ,[Minimum Rate]
  ,[Willing to relocate]
  ,[Visa Expiry]
  ,[Visa Type]
  ,[CV Received]
  ,[Part Time]
  ,[Own Transport]
  ,[Exclusive]
  ,[Preferences, Experinces, Personal Attributes]
  ,[Work History Link]
  ,date_of_birth';

    EXECUTE (REPLACE(sql_start, '#table', '#p7m_candidates_phase_1') || sql_where || sql_end );

SET sql_where = '
WHERE EXISTS (SELECT 1 FROM person_type pt
              WHERE per.person_ref = pt.person_ref AND pt.type IN(''A'', ''C''))
  AND EXISTS (SELECT 1 FROM event_role er
                INNER JOIN event e ON er.event_ref = e.event_ref
              WHERE e.type IN (''Q13'',''Q15'')
                AND person_ref IS NOT NULL
                AND e.create_timestamp >= CAST(''2012-10-01'' AS DATETIME)
                AND er.type IN (''D'', ''K'')
                AND EXISTS (SELECT 1
                            FROM event_role ru
                            WHERE ru.team IN(SELECT [value]
                                             FROM #p7m_vars WHERE [key] = ''teams'')
                              AND ru.event_ref = er.event_ref)
                AND per.person_ref = er.person_ref)
  AND per.person_ref NOT IN(SELECT ref FROM #p7m_candidates_phase_1)';

    EXECUTE (REPLACE(sql_start, '#table', '#p7m_candidates_reg_int') || sql_where || sql_end );

SET sql_where = '
WHERE EXISTS (SELECT 1 FROM person_type pt
              WHERE per.person_ref = pt.person_ref AND pt.type IN(''A'', ''C''))
  AND EXISTS (SELECT 1 FROM event_role er
                INNER JOIN event e ON er.event_ref = e.event_ref
              WHERE e.type IN(''F'', ''H'')
                AND er.type IN(''F'', ''H'')
                AND e.create_timestamp > DATEADD(MONTH, -24, GETDATE())
                AND person_ref IS NOT NULL
                AND EXISTS (SELECT 1
                            FROM event_role ru
                            WHERE ru.team IN(SELECT [value]
                                             FROM #p7m_vars WHERE [key] = ''teams'')
                              AND ru.event_ref = er.event_ref)
                AND per.person_ref = er.person_ref)
  AND per.person_ref NOT IN(SELECT ref FROM #p7m_candidates_phase_1)
  AND per.person_ref NOT IN(SELECT ref FROM #p7m_candidates_reg_int)';
    
    EXECUTE (REPLACE(sql_start, '#table', '#p7m_candidates_off_2y') || sql_where || sql_end );
    
-- Output CSV files
    BEGIN
      DECLARE v_csv VARCHAR(8000);
      DECLARE v_ref VARCHAR(8000);
      DECLARE c_csv CURSOR FOR
         SELECT
          'UNLOAD SELECT ''"' || LIST(cname, '","') || '"'''
          || ' UNION ALL SELECT ''"''||REPLACE(TRIM(['
          || LIST(cname, ']),''"'',''""'')||''","''||REPLACE(TRIM([')
          || ']),''"'',''""'')||''"'''
          || ' FROM #p7m_' || tname
          || ' TO ''' || csv_file_path || tname || '.csv'''
          || ' FORMAT ASCII QUOTES off ESCAPES off'
          ,'UNLOAD SELECT ref '
          || ' FROM #p7m_' || tname
          || ' ORDER BY ref'
          || ' TO ''' || csv_file_path || tname || '_refs.csv'''
          || ' FORMAT ASCII QUOTES off ESCAPES off'
        FROM #p7m_meta
        GROUP BY
          tname;
      OPEN c_csv;
      FETCH c_csv INTO v_csv, v_ref;
      WHILE SQLCODE = 0 LOOP
        EXECUTE (v_csv);
        EXECUTE (v_ref);
        FETCH c_csv INTO v_csv, v_ref;
      END LOOP;
      CLOSE c_csv;
      DEALLOCATE c_csv;
    END;

  END;
END;
