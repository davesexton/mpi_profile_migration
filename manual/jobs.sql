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
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Ref');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Client');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Contact / Booked By');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Job Title');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Number Required');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Start Date');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'End Date');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Consultant 1');
    INSERT INTO #p7m_meta VALUES('jobs_contract', '% Split');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Journal Notes');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Primary Job Category');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Pre AWR Charge');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Pre AWR Pay');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Pay Type');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Standard Hours');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Reporting To');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Address Line 1');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Address Line 2');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Locality');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Town');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'County');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Post Code');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Country');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Locations');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Job Category');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Close or Cancel Job');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Skills and Languages Required');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Industry Sectors');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Qualifications Required');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Personal Attributes');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Owning Consultant');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Owning Office');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Filled Date');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Job Source');
    INSERT INTO #p7m_meta VALUES('jobs_contract', 'Status');

    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Ref');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Client');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Contact / Booked By');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Owning Consultant');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Job Title');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Job Category');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Number Required');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Expected Start Date');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Open Since');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Salary From');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Salary To');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Job Source');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Fee %');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Consultant 1');
    INSERT INTO #p7m_meta VALUES('jobs_perm', '% Split');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Journal Notes');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Address Line 1');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Address Line 2');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Locality');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Town');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'County');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Post Code');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Country');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Locations');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Job Category ');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Close or Cancel Job');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Min Education Level');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Skills and Languages Required');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Industry Sectors');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Years Experience (Qualifications Required)');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Qualifications Required');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Personal Attributes');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Other Benefits');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Owning Office');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Owning Consultant ');
    INSERT INTO #p7m_meta VALUES('jobs_perm', 'Status');

-- Load contract jobs  
SELECT
  [Ref]
  ,[Client]
  ,[Contact / Booked By]
  ,[Job Title]
  ,[Number Required]
  ,[Start Date]
  ,[End Date]
  ,[Consultant 1]
  ,[% Split]
  ,[Journal Notes]
  ,LIST(CASE WHEN code_type = 1000 THEN code_description END, '; ') AS [Primary Job Category]
  ,[Pre AWR Charge]
  ,[Pre AWR Pay]
  ,[Pay Type]
  ,[Standard Hours]
  ,[Reporting To] 
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Post Code]
  ,[Country]
  ,LIST(CASE WHEN code_type = 1015 THEN code_description END, '; ') AS [Locations]
  ,LIST(CASE WHEN code_type = 1000 THEN code_description END, '; ') AS [Job Category]
  ,[Close or Cancel Job]
  ,LIST(CASE WHEN code_type IN(1007, 1010, 1011, 1012, 1014, 1016, 1017, 1018,
                               1008, 1036, 1039, 1041,
                               1030) 
             THEN code_description END, '; ') AS [Skills and Languages Required]
  ,LIST(CASE WHEN code_type = 1005 THEN code_description END, '; ') AS [Industry Sectors]
  ,LIST(CASE WHEN code_type IN(1020, 1025) THEN code_description END, '; ') AS [Qualifications Required]
  ,[Personal Attributes]
  ,[Owning Consultant]
  ,[Owning Office]
  ,[Filled Date]
  ,[Job Source]
  ,[Status]
INTO #p7m_jobs_contract
FROM (
SELECT DISTINCT
  o.opportunity_ref AS [Ref]
  ,org.name AS [Client]
  ,p.displayname AS [Contact / Booked By]
  ,o.displayname AS [Job Title]
  ,CAST(no_persons_reqd AS VARCHAR) AS [Number Required]
  ,REPLACE(CONVERT(VARCHAR(11), tv.start_date, 106), ' ', '-') AS [Start Date]
  ,REPLACE(CONVERT(VARCHAR(11), tv.end_date, 106), ' ', '-') AS [End Date]
  ,ru.displayname AS [Consultant 1]
  ,'100' AS [% Split]
  ,CAST(o.opportunity_ref AS VARCHAR) + ' - P7 Opp Ref' AS [Journal Notes]
  ,CAST(tv.rate1_invoice AS VARCHAR) AS [Pre AWR Charge]
  ,CAST(tv.rate1_payment AS VARCHAR) AS [Pre AWR Pay]
  ,tv.time_unit AS [Pay Type]
  ,CAST(tv.hours_per_day AS VARCHAR) AS [Standard Hours]
  ,tv.working_for AS [Reporting To] 
  ,a.address_line_1 AS [Address Line 1]
  ,a.address_line_2 AS [Address Line 2]
  ,a.address_line_3 AS [Locality]
  ,a.post_town AS [Town]
  ,a.county_state AS [County]
  ,a.zipcode AS [Post Code]
  ,c.description AS [Country]
  ,lrs.description AS [Close or Cancel Job]
  ,o.notes AS [Personal Attributes]
  ,ru.displayname AS [Owning Consultant]
  ,o.responsible_team AS [Owning Office]
  ,CAST(o.date_closed AS VARCHAR) AS [Filled Date]
  ,src.description AS [Job Source]
  ,lrs.description AS [Status]
  ,sc.code_type
  ,sc.code
  ,l.description AS code_description
FROM opportunity o
  LEFT OUTER JOIN address a ON o.address_ref = a.address_ref
  LEFT OUTER JOIN temporary_vac tv ON o.opportunity_ref = tv.opportunity_ref
  LEFT OUTER JOIN opport_role rl ON o.opportunity_ref = rl.opportunity_ref
                                AND rl.role_type = 'C1'
  LEFT OUTER JOIN person p ON rl.person_ref = p.person_ref
  LEFT OUTER JOIN person ru ON o.responsible_user = ru.person_ref
  LEFT OUTER JOIN organisation org ON o.organisation_ref = org.organisation_ref
  LEFT OUTER JOIN lookup lrs ON o.record_status = lrs.code AND lrs.code_type = 119
  LEFT OUTER JOIN lookup lt ON o.type = lt.code AND lt.code_type = 117
  LEFT OUTER JOIN lookup ltu ON tv.time_unit = ltu.code AND ltu.code_type = 197
  LEFT OUTER JOIN lookup c ON a.country_code = c.code AND c.code_type = 100
  LEFT OUTER JOIN lookup src ON o.source = src.code AND src.code_type = 108
  LEFT OUTER JOIN search_code sc ON o.opportunity_ref = sc.opportunity_ref 
     AND sc.code_type IN(1000, 1015, 1005,
                         1007, 1010, 1011, 1012, 1014, 1016, 1017, 1018,
                         1008, 1036, 1039, 1041,
                         1030,
                         1020, 1025
                         )
     AND sc.search_type = 5
  LEFT OUTER JOIN lookup l ON sc.code_type = l.code_type AND sc.code = l.code
WHERE o.record_status IN('L', 'L1')
  AND o.type = 'E'
  AND o.responsible_team IN(SELECT [value]
                            FROM #p7m_vars WHERE [key] = 'teams')

) a
GROUP BY
  [Ref]
  ,[Client]
  ,[Contact / Booked By]
  ,[Job Title]
  ,[Number Required]
  ,[Start Date]
  ,[End Date]
  ,[Consultant 1]
  ,[% Split]
  ,[Journal Notes]
  ,[Pre AWR Charge]
  ,[Pre AWR Pay]
  ,[Pay Type]
  ,[Standard Hours]
  ,[Reporting To] 
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Post Code]
  ,[Country]
  ,[Close or Cancel Job]
  ,[Personal Attributes]
  ,[Owning Consultant]
  ,[Owning Office]
  ,[Filled Date]
  ,[Job Source]
  ,[Status]  
;

-- Load perm jobs
SELECT
  [Ref]
  ,[Client]
  ,[Contact / Booked By]
  ,[Owning Consultant]
  ,[Job Title]
  ,LIST(CASE WHEN code_type = 1000 THEN code_description END, '; ') AS [Job Category]
  ,[Number Required]
  ,[Expected Start Date]
  ,[Open Since]
  ,[Salary From]
  ,[Salary To]
  ,[Job Source]
  ,[Fee %]
  ,[Consultant 1]
  ,[% Split]
  ,[Journal Notes]
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Post Code]
  ,[Country]
  ,LIST(CASE WHEN code_type = 1015 THEN code_description END, '; ') AS [Locations]
  ,LIST(CASE WHEN code_type = 1000 THEN code_description END, '; ') AS [Job Category ]
  ,[Close or Cancel Job]
  ,LIST(CASE WHEN code_type = 1020 THEN code_description END, '; ') AS [Min Education Level]
  ,LIST(CASE WHEN code_type IN(1007, 1010, 1011, 1012, 1014, 1016, 1017, 1018,
                               1008, 1036, 1039, 1041,
                               1030) 
             THEN code_description END, '; ') AS [Skills and Languages Required]
  ,LIST(CASE WHEN code_type = 1005 THEN code_description END, '; ') AS [Industry Sectors]
  ,[Years Experience (Qualifications Required)]
  ,LIST(CASE WHEN code_type IN(1020, 1025) THEN code_description END, '; ') AS [Qualifications Required]
  ,[Personal Attributes]
  ,[Other Benefits]
  ,[Owning Office]
  ,[Owning Consultant ]
  ,[Status]
INTO #p7m_jobs_perm
FROM (
SELECT
  o.opportunity_ref
  ,org.name AS [Client]
  ,p.displayname AS [Contact / Booked By]
  ,ru.displayname AS [Owning Consultant]
  ,o.displayname AS [Job Title]
  ,CAST(no_persons_reqd AS VARCHAR) AS [Number Required]
  ,REPLACE(CONVERT(VARCHAR(11), o.date_opened, 106), ' ', '-') AS [Expected Start Date]
  ,REPLACE(CONVERT(VARCHAR(11), o.date_opened, 106), ' ', '-') AS [Open Since]
  ,CAST(pv.lower_income AS VARCHAR) AS [Salary From]
  ,CAST(pv.upper_income AS VARCHAR) AS [Salary To]
  ,src.description AS [Job Source]
  ,CAST(pv.agreed_fee AS VARCHAR) AS [Fee %]
  ,ru.displayname AS [Consultant 1]
  ,'100' AS [% Split]
  ,CAST(o.opportunity_ref AS VARCHAR) + ' - P7 Opp Ref' AS [Journal Notes]
  ,a.address_line_1 AS [Address Line 1]
  ,a.address_line_2 AS [Address Line 2]
  ,a.address_line_3 AS [Locality]
  ,a.post_town AS [Town]
  ,a.county_state AS [County]
  ,a.zipcode AS [Post Code]
  ,c.description AS [Country]
  ,lrs.description AS [Close or Cancel Job]
  ,CAST(lower_age AS VARCHAR) || ' to ' || CAST(upper_age AS VARCHAR) 
     AS [Years Experience (Qualifications Required)]
  ,o.notes AS [Personal Attributes]
  ,pv.package AS [Other Benefits]
  ,o.responsible_team AS [Owning Office]
  ,ru.displayname AS [Owning Consultant ]
  ,lrs.description AS [Status]
  ,sc.code_type
  ,sc.code
  ,l.description AS code_description
FROM opportunity o
  LEFT OUTER JOIN address a ON o.address_ref = a.address_ref
  LEFT OUTER JOIN permanent_vac pv ON o.opportunity_ref = pv.opportunity_ref
  LEFT OUTER JOIN opport_role rl ON o.opportunity_ref = rl.opportunity_ref
                                AND rl.role_type = 'C1'
  LEFT OUTER JOIN person p ON rl.person_ref = p.person_ref
  LEFT OUTER JOIN person ru ON o.responsible_user = ru.person_ref
  LEFT OUTER JOIN organisation org ON o.organisation_ref = org.organisation_ref
  LEFT OUTER JOIN lookup c ON a.country_code = c.code AND c.code_type = 100
  LEFT OUTER JOIN lookup lrs ON o.record_status = lrs.code AND lrs.code_type = 119
  LEFT OUTER JOIN lookup lt ON o.type = lt.code AND lt.code_type = 117
  LEFT OUTER JOIN lookup src ON o.source = src.code AND src.code_type = 108
  LEFT OUTER JOIN search_code sc ON o.opportunity_ref = sc.opportunity_ref 
     AND sc.code_type IN(1000, 1015, 1020, 1005,
                         1007, 1010, 1011, 1012, 1014, 1016, 1017, 1018,
                         1008, 1036, 1039, 1041,
                         1030,
                         1020, 1025
                         )
     AND sc.search_type = 5
  LEFT OUTER JOIN lookup l ON sc.code_type = l.code_type AND sc.code = l.code
WHERE o.record_status IN('L', 'L1')
  AND o.type IN('C', 'CR')
  AND o.responsible_team IN(SELECT [value]
                            FROM #p7m_vars WHERE [key] = 'teams')
) a
GROUP BY
  [Ref]
  ,[Client]
  ,[Contact / Booked By]
  ,[Owning Consultant]
  ,[Job Title]
  ,[Number Required]
  ,[Expected Start Date]
  ,[Open Since]
  ,[Salary From]
  ,[Salary To]
  ,[Job Source]
  ,[Fee %]
  ,[Consultant 1]
  ,[% Split]
  ,[Journal Notes]
  ,[Address Line 1]
  ,[Address Line 2]
  ,[Locality]
  ,[Town]
  ,[County]
  ,[Post Code]
  ,[Country]
  ,[Close or Cancel Job]
  ,[Years Experience (Qualifications Required)]
  ,[Personal Attributes]
  ,[Other Benefits]
  ,[Owning Office]
  ,[Owning Consultant ]
  ,[Status]
;

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
