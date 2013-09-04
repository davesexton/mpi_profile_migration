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
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Ref');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Work History Link');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Candidate');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Company');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Company Displayname');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Job Title');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Status');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'From');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'To');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Rate / Salary');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Manager');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Telephone No.');
    INSERT INTO #p7m_meta VALUES('work_history_phase_1', 'Notes');

-- Load work history phase 1
SELECT
  pos.position_ref AS [Ref]
  ,CAST(pos.person_ref AS VARCHAR) AS [Work History Link]
  ,per.displayname AS [Candidate]
  ,org.name AS [Company]
  ,org.displayname AS [Company Displayname]
  ,pos.displayname AS [Job Title]
  ,stat.description AS [Status]
  ,CAST(start_date AS VARCHAR) AS [From]
  ,CAST(end_date AS VARCHAR) AS [To]
  ,COALESCE(CAST(pe.income AS VARCHAR), te.hours_details) AS [Rate / Salary]
  ,mgr.displayname AS [Manager]
  ,ISNULL('="' + pos.telephone_number + '"', '') AS [Telephone No.]
  ,REPLACE(REPLACE(pos.notes, '\x0d', ' '), '\x0a', ' ') AS [Notes]
INTO #p7m_work_history_phase_1
FROM position pos
  INNER JOIN person per ON pos.person_ref = per.person_ref
  LEFT OUTER JOIN organisation org ON pos.organisation_ref = org.organisation_ref
  LEFT OUTER JOIN lookup stat ON pos.record_status = stat.code AND stat.code_type = 132
  LEFT OUTER JOIN permanent_emp pe ON pos.position_ref = pe.position_ref
  LEFT OUTER JOIN temporary_emp te ON pos.position_ref = te.position_ref
  LEFT OUTER JOIN person mgr ON pos.manager_person_ref = mgr.person_ref
WHERE EXISTS (SELECT 1
              FROM person_type pts
              WHERE pts.type IN('A', 'C')
                AND pos.person_ref = pts.person_ref
                AND EXISTS(SELECT 1
                           FROM event_role er
                             INNER JOIN event e ON er.event_ref = e.event_ref
                             INNER JOIN opportunity o ON e.opportunity_ref = o.opportunity_ref
                           WHERE er.type IN('D', 'K', '1', 'A1', 'I', 'H', 'F', 'G1')
                             AND o.responsible_team IN(SELECT [value]
                                                       FROM #p7m_vars WHERE [key] = 'teams')
                             AND o.record_status IN('L', 'L1')
                             AND pts.person_ref = er.person_ref))
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
