BEGIN

  DECLARE var_text VARCHAR(8000);

  SET var_text = '
teams=BKCH,CMCH,CMIC,MSCH,PSCH,DUMMY,SITL,SLEM,VDPL
zip_exe_path=C:\Documents and Settings\davesexton\Desktop\migration\bin\7za.exe
csv_file_path=C:\Documents and Settings\davesexton\Desktop\migration\
csv_file_pathx=s:\mig\
migration_team=XXXX
migration_user=0
candidate_education_code_type=1020
candidate_hot_code_type=2080
candidate_hot_code=01
candidate_industry_code_type=1005
candidate_job_category_code_type=1000
candidate_location_code_type=1015
candidate_qualification_code_type=1025,1020
candidate_skill_code_type=1007,1010,1011,1012,1014,1016,1017,1018,1055
candidate_tracking_consultant_code_type=1055
job_contact_role_type=C1
client_employer_only_record_status_code=Y
client_industry_code_type=1005
client_location_code_type=1015
contact_industry_code_type=1005
contact_job_category_code_type=1000
contact_location_code_type=1015
contact_role_code_type=1045
contact_skill_code_type=1007,1010,1011,1012,1014,1016,1017,1018,1055
contact_tracking_consultant_code_type=1055
contact_record_status_code=C
contact_contact_status_code=2,3,6
job_close_reason_type=X2,X3,X4
job_competitor_type=X3
job_contact_fee_event_type=1FA
job_contract_type=E
job_education_code_type=1020
job_industry_code_type=1005
job_job_category_code_type=1000
job_lead_record_status_code=L1
job_location_code_type=1015
job_perm_type=C,CR
job_qualification_code_type=1025,1020
job_skill_code_type=1007,1010,1011,1012,1014,1016,1017,1018,1008,1036,1039,1041,1030
journal_general_type=Q11,Q14,P15,KA1,G,P13
journal_send_email_type=KE01,P05,KA2
journal_call_made_log_type=P11,KD2
journal_client_visit_type=P14
journal_internal_interview_arranged_type=Q13,Q15
shortlist_cv_event_type=KE03,Q21
shortlist_interview_event_type=Q31,Q32,Q33,Q34,Q35,Q36
shortlist_offer_event_type=F,H
shortlist_shortlisted_event_type=A
interview_external_event_type=Q31,Q32,Q33,Q34,Q35,Q36
interview_internal_event_type=Q13,Q15
event_role_candidate_type=A,1,D,F,H,K
event_role_contact_type=C1
event_role_consultant_type=U1
perm_assign_perm_offer_event_type=F
perm_assign_perm_fee_event_type=1PA
perm_assign_placed_event_outcome=F3
perm_assign_deleted_event_outcome=DEL
';

  BEGIN

-- Create variables

    DECLARE csv_file_path VARCHAR(255);
    DECLARE log_file_path VARCHAR(255);
    DECLARE zip_exe_path VARCHAR(255);
    DECLARE migration_user INT;
    DECLARE migration_team VARCHAR(10);

-- Create procs

    IF OBJECT_ID('logger') > 0 THEN
      DROP PROCEDURE logger;
    END IF;

    IF OBJECT_ID('write_csv') > 0 THEN
      DROP PROCEDURE write_csv;
    END IF;

    CREATE PROCEDURE logger (IN log_text VARCHAR(255), IN log_file_path VARCHAR(255))
    BEGIN

      EXECUTE ('xp_cmdshell ''echo ' || CAST(GETDATE() AS VARCHAR(23)) ||
               ': ' || log_text || ' >> "' || log_file_path || '"''');
      PRINT CAST(GETDATE() AS VARCHAR(23)) || ': ' || log_text;

    END;


    CREATE PROCEDURE write_csv (IN table_name VARCHAR(255), IN csv_file_path VARCHAR(255))
    BEGIN
      DECLARE sql_text VARCHAR(4000);

      SELECT
        'UNLOAD SELECT ''"' || REPLACE(UPPER(cname), ',', '","') || '"'''
        || ' UNION ALL SELECT ''"''||REPLACE(TRIM('
        || REPLACE(cname, ',', '),''"'',''""'')||''","''||REPLACE(TRIM(')
        || '),''"'',''""'')||''"'''
        || ' FROM #p7m_'
        || tname
        || ' TO ''' || csv_file_path
        || tname
        || '.csv'' FORMAT ASCII QUOTES off ESCAPES off'
      INTO sql_text
      FROM #p7m_meta
      WHERE tname = table_name;

      EXECUTE (sql_text);

    END;


-- Create tables

    CREATE TABLE #p7m_vars
    (
      [key] VARCHAR(255)
      ,[value] VARCHAR(255)
      ,[value_int] INT
      ,search_type INT
    );

    CREATE TABLE #p7m_meta
    (
      tname VARCHAR(255)
      ,cname VARCHAR(8000)
    );

-- Load vars table

    BEGIN
      DECLARE pos INT;
      DECLARE ipos INT;
      DECLARE k VARCHAR(255);
      DECLARE v VARCHAR(255);
      WHILE CHARINDEX(CHAR(10), var_text) > 0 LOOP
        SET pos = CHARINDEX(CHAR(10), var_text);
        SET k = SUBSTRING(var_text, 1, pos - 1);
        SET v = TRIM(SUBSTRING(k, CHARINDEX('=', k) + 1)) + ',';
        SET k = TRIM(SUBSTRING(k, 1, CHARINDEX('=', k) - 1));

        WHILE CHARINDEX(',', v) > 0 LOOP
          SET ipos = CHARINDEX(',', v);

          INSERT INTO #p7m_vars VALUES(k, TRIM(SUBSTRING(v, 1, ipos - 1)), NULL, NULL);

          SET v = SUBSTRING(v, ipos + 1);
        END LOOP;

        SET var_text = SUBSTRING(var_text, pos + 1);
      END LOOP;
    END;

    UPDATE #p7m_vars
    SET
      value_int = CAST([value] AS INT)
      ,search_type = CASE WHEN [key] LIKE 'consultant%' THEN 1
                          WHEN [key] LIKE 'client%' THEN 3
                          WHEN [key] LIKE 'contact%' THEN 4
                          WHEN [key] LIKE 'job%' THEN 5
                          END
    WHERE [value] NOT LIKE '%[a-zA-Z]%';

    SELECT
      MAX(CASE [key] WHEN 'csv_file_path' THEN [value] END)
      ,MAX(CASE [key] WHEN 'zip_exe_path' THEN [value] END)
      ,MAX(CASE [key] WHEN 'migration_user' THEN [value] END)
      ,MAX(CASE [key] WHEN 'migration_team' THEN [value] END)
    INTO
      csv_file_path
      ,zip_exe_path
      ,migration_user
      ,migration_team
    FROM #p7m_vars;

    SET log_file_path = csv_file_path || 'migration.log';

    EXECUTE ('xp_cmdshell ''del "' || log_file_path || '"''');
    EXECUTE ('xp_cmdshell ''del "' || csv_file_path || 'documents.zip"''');
    EXECUTE ('xp_cmdshell ''del "' || csv_file_path || '*.csv"''');

    CALL logger('Start migration', log_file_path);

-- Load meta data

    INSERT INTO #p7m_meta VALUES('clients',
      'client_id,createddate,created_by,updateddate,updated_by,street1,street2,locality,' ||
      'town,county,post_code,country,name,status,web_add,source,location,industry,' ||
      'fin_year,client_type,perm_consultant,perm_team,contract_consultant,contract_team,office,' ||
      'work_telephone,fax_telephone,consultant_notes');

    INSERT INTO #p7m_meta VALUES('legal_entity',
      'legal_entity_id,createddate,created_by,updateddate,updated_by,street1,street2,' ||
      'locality,town,county,post_code,country,industry,name,trad_name,status,office,' ||
      'tel_number');

    INSERT INTO #p7m_meta VALUES('contacts',
      'contact_id,person_id,createddate,created_by,updateddate,updated_by,street1,' ||
      'street2,locality,town,county,post_code,country,status,contact_role,e_shot,' ||
      'work_email_add,perm_consultant,perm_team,contract_consultant,contract_team,office' ||
      ',title,first_name,last_name,full_name,salutation,job_title,work_tel_number,' ||
      'work_extention,fax_no,mobile_no,contact_notes');

    INSERT INTO #p7m_meta VALUES('contract_jobs',
      'job_id,createddate,created_by,updateddate,updated_by,street1,street2,locality,' ||
      'town,county,post_code,country,no_req,std_hours,pay_period,fixed_term,chrg_rate,' ||
      'pay_rate,status,job_title,start_dt,end_date,job_src,report_to,job_type,location_cd,' ||
      'cons1,cons1_perc,close_reason,lead,competitor,filled_dt,consultant,team,office,' ||
      'personal_attributes');

    INSERT INTO #p7m_meta VALUES('perm_jobs',
      'job_id,createddate,created_by,updateddate,updated_by,street1,street2,locality,' ||
      'town,county,post_code,country,status,job_title,start_dt,job_src,job_type,' ||
      'closed_dt,location_cd,close_reason,lead,competitor,filled_dt,' ||
      'consultant,team,office,fee_perc,sal_from,sal_to,fixed_term,open_since,educ_level,' ||
      'no_req,personal_attributes');

    INSERT INTO #p7m_meta VALUES('contract_lead_jobs',
      'job_id,createddate,created_by,updateddate,updated_by,street1,street2,locality,' ||
      'town,county,post_code,country,no_req,std_hours,pay_period,chrg_rate,pay_rate,' ||
      'status,job_title,start_dt,job_src,job_type,location_cd,' ||
      'close_reason,lead,filled_dt,consultant,team,office,personal_attributes');

    INSERT INTO #p7m_meta VALUES('perm_lead_jobs',
      'job_id,createddate,created_by,updateddate,updated_by,street1,street2,locality,' ||
      'town,county,post_code,country,status,job_title,start_dt,job_src,job_type,' ||
      'closed_dt,location_cd,cons1,cons1_perc,lead,filled_dt,consultant,team,office,' ||
      'fee_perc,sal_from,sal_to,open_since,educ_level,no_req,personal_attributes');

    INSERT INTO #p7m_meta VALUES('candidates',
      'candidate_id,createddate,created_by,updateddate,updated_by,street1,street2,locality,' ||
      'town,county,post_code,country,hot,source,status,not_period,own_trans,high_edu_lev,' ||
      'def_role,avail_from,visa_exp,cv_received,visa_type,ex_clusive,e_shot,cand_type,' ||
      'part_time,rate_req,salary_req,ote_req,p_perm,p_contr,relocate,look_for,home_email,' ||
      'work_email,perm_consultant,perm_team,contract_consultant,contract_team,office,title,' ||
      'first_name,last_name,fullname,salutation,initials,home_tel_number,work_tel_number,' ||
      'work_extension,mobile_tel_number,notes');

    INSERT INTO #p7m_meta VALUES('x_client_sub',
      'id,client,parent');

    INSERT INTO #p7m_meta VALUES('x_le_client',
      'id,le,client');

    INSERT INTO #p7m_meta VALUES('x_client_job',
      'id,client,contact,job');

    INSERT INTO #p7m_meta VALUES('x_client_con',
      'id,client,contact');

    INSERT INTO #p7m_meta VALUES('contact_industry_sectors',
      'id,contact_id,industry');

    INSERT INTO #p7m_meta VALUES('contact_job_categories',
      'id,contact_id,job_category');

    INSERT INTO #p7m_meta VALUES('contact_skills',
      'id,contact_id,skill');

    INSERT INTO #p7m_meta VALUES('contact_locations',
      'id,contact_id,location');

    INSERT INTO #p7m_meta VALUES('perm_job_industry_sectors',
      'id,job_id,industry');

    INSERT INTO #p7m_meta VALUES('perm_job_job_categories',
      'id,job_id,job_category');

    INSERT INTO #p7m_meta VALUES('perm_job_qualifications',
      'id,job_id,qual');

    INSERT INTO #p7m_meta VALUES('perm_job_skills',
      'id,job_id,skill');

    INSERT INTO #p7m_meta VALUES('contract_job_industry_sectors',
      'id,job_id,industry');

    INSERT INTO #p7m_meta VALUES('contract_job_job_categories',
      'id,job_id,job_category');

    INSERT INTO #p7m_meta VALUES('contract_job_qualifications',
      'id,job_id,qual');

    INSERT INTO #p7m_meta VALUES('contract_job_skills',
      'id,job_id,skill');

    INSERT INTO #p7m_meta VALUES('candidate_industry_sectors',
      'id,candidate_id,industry');

    INSERT INTO #p7m_meta VALUES('candidate_job_categories',
      'id,candidate_id,job_category');

    INSERT INTO #p7m_meta VALUES('candidate_locations',
      'id,candidate_id,location');

    INSERT INTO #p7m_meta VALUES('candidate_qualifications',
      'id,candidate_id,qual');

    INSERT INTO #p7m_meta VALUES('candidate_skills',
      'id,candidate_id,skill');

    INSERT INTO #p7m_meta VALUES('candidate_prev_assign',
      'prev_assign_id,candidate_id,createddate,created_by,updateddate,updated_by,salary,' ||
      'status,start_date,end_date,job_title,assig_type,prev_co,prv_manager,prv_man_tel,' ||
      'notes,pay_rate,office');

    INSERT INTO #p7m_meta VALUES('x_pa_client',
      'id,prev_assign,contact,client');

    INSERT INTO #p7m_meta VALUES('x_prev_assig_cand',
      'id,assignment,candidate');

    INSERT INTO #p7m_meta VALUES('ext_interviews',
      'interview_id,createddate,created_by,updateddate,updated_by,street1,street2,locality,' ||
      'town,county,post_code,country,iv_cont,stage,iv_date,iv_start,iv_end,iv_att,internal,' ||
      'perm_consultant,perm_team,contract_consultant,contract_team,office');

    INSERT INTO #p7m_meta VALUES('int_interviews',
      'interview_id,createddate,created_by,updateddate,updated_by,stage,iv_date,iv_start,' ||
      'iv_end,int_office,internal,int_cons,perm_consultant,perm_team,contract_consultant,' ||
      'contract_team,office');

    INSERT INTO #p7m_meta VALUES('perm_assign',
      'assignment_id,createddate,created_by,updateddate,updated_by,salary,fee,start_dt,' ||
      'cons1,cons1_perc,fee_pec,status,job_title,assig_type,filled_dt,consultant,team,office');

    INSERT INTO #p7m_meta VALUES('contr_assign',
      'assignment_id,createddate,created_by,updateddate,updated_by,status,start_dt,end_dt,' ||
      'cons1,cons1_perc,job_title,assig_type,filled_dt,orig_start,std_hours,std_days,' ||
      'prim_jcat_aw,exempt_aw,cont_type,margin_val,margin_pcnt,pay_period,chrg_rate,' ||
      'pay_rate,consultant,team,office');

    INSERT INTO #p7m_meta VALUES('x_assig_cand',
      'id,assignment,job,candidate');

    INSERT INTO #p7m_meta VALUES('shortlist',
      'shortlist_id,createddate,created_by,perm_consultant,perm_team,contract_consultant,' ||
      'contract_team,office,date_short,time_short,status,last_cv_dt,last_cv_tm,last_iv_dt,' ||
      'last_iv_tm,last_cv_by,last_iv_by,last_of_dt,last_of_tm,last_of_by,offer_sal,' ||
      'rej_of_dt,rej_of_tm,rej_of_by,rej_dt,rej_tm,rej_by,last_iv_st,rejected_by,rejected_res,' ||
      'progress,accepted_by,acc_off_date,acc_off_time');

    INSERT INTO #p7m_meta VALUES('x_short_cand',
      'id,shortlist,job,candidate,contact,client');

    INSERT INTO #p7m_meta VALUES('x_short_iv',
      'id,shortlist,interview');

    INSERT INTO #p7m_meta VALUES('general_journals',
      'journal_id,datetime,consultant,candidate,contact,client,job,notes');

    INSERT INTO #p7m_meta VALUES('send_email_journals',
      'journal_id,datetime,consultant,candidate,contact,client,job,notes');

    INSERT INTO #p7m_meta VALUES('call_made_log_journals',
      'journal_id,datetime,consultant,candidate,contact,client,job,notes');

    INSERT INTO #p7m_meta VALUES('client_visit_arranged_journals',
      'journal_id,datetime,consultant,candidate,contact,client,job,notes');

    INSERT INTO #p7m_meta VALUES('client_visit_attended_journals',
      'journal_id,datetime,consultant,candidate,contact,client,job,notes');

    INSERT INTO #p7m_meta VALUES('documents',
      'document_id,document_path,document_type,entity_reference,' ||
      'document_ext,document_description');

--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, 'perm_team,', '');
--
--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, 'contract_team,', '');
--
--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, 'team,', '');
--
--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, 'close_reason,', '');
--
--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, 'lead,', '');
--
--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, 'competitor,', '');
--
--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, 'internal,', '');
--
--    UPDATE #p7m_meta
--    SET cname = REPLACE(cname, ',progress,accepted_by,acc_off_date,acc_off_time', '');
--
--    DELETE FROM #p7m_meta
--    WHERE tname IN('perm_lead_jobs', 'contract_lead_jobs');

----------------------------------------------------------------------------
-- Load data for X_CLIENT_CON.CSV

    CALL logger('Load X_CLIENT_CON', log_file_path);

    SELECT DISTINCT
      organisation_ref
    INTO #client_list
    FROM opportunity
    WHERE organisation_ref IN(658,4326,6603,16676,17354,17729,19979,
                              24310,390450,391256,391412,393483,399584,477230,993271)
    ;

    BEGIN
      DECLARE i INT;
      SET i = 0;
      WHILE (i < 6) LOOP

        INSERT INTO #client_list
        SELECT parent_organ_ref
        FROM organisation org
          INNER JOIN #client_list cl ON org.organisation_ref = cl.organisation_ref
        WHERE parent_organ_ref NOT IN(SELECT organisation_ref FROM #client_list);

        SET i = i + 1;
      END LOOP;
    END;

    CREATE UNIQUE INDEX p7m_client_list_idx ON #client_list (organisation_ref);

    SELECT
      IDENTITY(10) AS [id]
      ,organisation_ref AS [client]
      ,position_ref AS [contact]
    INTO #p7m_x_client_con
    FROM position pos
    WHERE organisation_ref IN(SELECT organisation_ref FROM #client_list)
      AND pos.contact_status IN(SELECT [value]
                                FROM #p7m_vars WHERE [key] = 'contact_contact_status_code')
      AND pos.record_status IN(SELECT [value]
                               FROM #p7m_vars WHERE [key] = 'contact_record_status_code')
    ;

    CREATE UNIQUE INDEX p7m_x_client_con_idx ON #p7m_x_client_con (client, contact);

    CALL write_csv('x_client_con', csv_file_path);

----------------------------------------------------------------------------
-- Load data for CLIENTS.CSV

    CALL logger('Load CLIENTS', log_file_path);

    SELECT
      o.organisation_ref AS [client_id]
      ,LEFT(o.create_timestamp, 10) AS [createddate]
      ,o.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,o.update_user AS [updated_by]
      ,a.address_line_1 AS [street1]
      ,a.address_line_2 AS [street2]
      ,a.address_line_3 AS [locality]
      ,a.post_town AS [town]
      ,a.county_state AS [county]
      ,a.zipcode AS [post_code]
      ,a.country_code AS [country]
      ,o.name AS [name]
      ,o.record_status AS [status]
      ,o.web_site_url AS [web_add]
      ,o.source AS [source]
      ,CAST(NULL AS CHAR(4)) AS [location]
      ,CAST(NULL AS CHAR(4)) AS [industry]
      ,o.financial_year_end AS [fin_year]
      ,o.type AS [client_type]
      ,o.responsible_user AS [perm_consultant]
      ,o.responsible_team AS [perm_team]
      ,o.responsible_user AS [contract_consultant]
      ,o.responsible_team AS [contract_team]
      ,o.responsible_team AS [office]
      ,a.telephone_number AS [work_telephone]
      ,a.fax_number AS [fax_telephone]
      ,REPLACE(REPLACE(o.notes, '\x0d', ''), '\x0a', '') AS [consultant_notes]
      ,parent_organ_ref AS parent_id
      ,CASE WHEN parent_organ_ref IS NULL THEN 'Y' ELSE 'N' END AS is_le
      ,CASE WHEN parent_organ_ref IS NULL THEN o.organisation_ref END AS le_id
    INTO #p7m_clients
    FROM organisation o
      LEFT OUTER JOIN address a ON o.organisation_ref = a.organisation_ref
         AND a.create_timestamp = (SELECT ISNULL(MAX(CASE main_address WHEN 'Y'
                                                                       THEN create_timestamp
                                                                       END)
                                                 ,MAX(create_timestamp))
                                   FROM address a1
                                   WHERE a.organisation_ref = a1.organisation_ref)
    WHERE o.organisation_ref IN(SELECT organisation_ref FROM #client_list);

    CREATE UNIQUE INDEX p7m_clients_idx ON #p7m_clients (client_id);

    UPDATE #p7m_clients
    SET
      cl.location = co.location
      ,cl.industry = co.industry
    FROM #p7m_clients cl
      INNER JOIN (SELECT
                    organisation_ref
                    ,MAX(CASE [key] WHEN 'client_location_code_type' THEN code END) AS location
                    ,MAX(CASE [key] WHEN 'client_industry_code_type' THEN code END) AS industry
                  FROM search_code sc
                    INNER JOIN #p7m_vars ON sc.code_type = [value_int]
                  WHERE sc.search_type = 3
                    AND [key] IN('client_location_code_type', 'client_industry_code_type')
                  GROUP BY
                    organisation_ref) co ON cl.client_id = co.organisation_ref;

    BEGIN
      DECLARE i INT;
      SET i = 0;
      WHILE (i < 6) LOOP

        UPDATE #p7m_clients
        SET le_id = p.client_id
        FROM #p7m_clients c
          INNER JOIN (SELECT *
                      FROM #p7m_clients
                      WHERE le_id IS NOT NULL) p ON c.parent_id = p.client_id
        WHERE c.le_id IS NULL;

        SET i = i + 1;
      END LOOP;
    END;

    CALL write_csv('clients', csv_file_path);

----------------------------------------------------------------------------
-- Load data for LEGAL_ENTITY.CSV

    CALL logger('Load LEGAL_ENTITY', log_file_path);

    SELECT
      client_id AS [legal_entity_id]
      ,createddate AS [createddate]
      ,created_by AS [created_by]
      ,updateddate AS [updateddate]
      ,updated_by AS [updated_by]
      ,street1 AS [street1]
      ,street2 AS [street2]
      ,locality AS [locality]
      ,town AS [town]
      ,county AS [county]
      ,post_code AS [post_code]
      ,country AS [country]
      ,industry AS [industry]
      ,name AS [name]
      ,name AS [trad_name]
      ,status AS [status]
      ,office AS [office]
      ,work_telephone AS [tel_number]
    INTO #p7m_legal_entity
    FROM #p7m_clients
    WHERE is_le = 'Y';

    CALL write_csv('legal_entity', csv_file_path);

----------------------------------------------------------------------------
-- Load data for CONTACTS.CSV

    CALL logger('Load CONTACTS', log_file_path);

    SELECT
      pos.position_ref AS [contact_id]
      ,pos.person_ref AS [person_id]
      ,LEFT(pos.create_timestamp, 10) AS [createddate]
      ,pos.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,pos.update_user AS [updated_by]
      ,a.address_line_1 AS [street1]
      ,a.address_line_2 AS [street2]
      ,a.address_line_3 AS [locality]
      ,a.post_town AS [town]
      ,a.county_state AS [county]
      ,a.zipcode AS [post_code]
      ,a.country_code AS [country]
      ,pos.record_status AS [status]
      ,CAST(NULL AS CHAR(4)) AS [contact_role]
      ,CASE pos.do_not_mailshot WHEN 'Y' THEN 'N' ELSE 'Y' END AS [e_shot]
      ,pos.email_address AS [work_email_add]
      ,pos.responsible_user AS [perm_consultant]
      ,CAST(NULL AS CHAR(4)) AS [perm_team]
      ,CAST(NULL AS INT) AS [contract_consultant]
      ,CAST(NULL AS CHAR(4)) AS [contract_team]
      ,CAST(NULL AS CHAR(4)) AS [office]
      ,per.title AS [title]
      ,per.first_name AS [first_name]
      ,per.Last_name AS [last_name]
      ,per.first_name || ' ' || per.Last_name AS [full_name]
      ,per.first_name AS [salutation]
      ,pos.displayname AS [job_title]
      ,ISNULL(pos.telephone_number, a.telephone_number) AS [work_tel_number]
      ,pos.telephone_ext AS [work_extention]
      ,pos.fax_number AS [fax_no]
      ,pos.mobile_telno AS [mobile_no]
      ,REPLACE(REPLACE(pos.notes, '\x0d', ''), '\x0a', '') AS [contact_notes]
    INTO #p7m_contacts
    FROM position pos
      INNER JOIN person per ON pos.person_ref = per.person_ref
      LEFT OUTER JOIN organisation org ON pos.organisation_ref = org.organisation_ref
      LEFT OUTER JOIN address a ON pos.address_ref = a.address_ref
    WHERE pos.position_ref IN(SELECT contact FROM #p7m_x_client_con)
    ;

    CREATE UNIQUE INDEX p7m_contacts_idx ON #p7m_contacts (contact_id, person_id);

    UPDATE #p7m_contacts
    SET contact_role = code
    FROM #p7m_contacts
      INNER JOIN search_code ON contact_id = position_ref
    WHERE search_type = 4
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'contact_role_code_type');

-- Update consultant and team

    UPDATE #p7m_contacts
    SET
      contract_consultant = perm_consultant
      ,perm_team = s.team
      ,contract_team = s.team
      ,office = s.team
    FROM #p7m_contacts con
      INNER JOIN person_type pt ON con.perm_consultant = pt.person_ref
      INNER JOIN staff s ON pt.person_type_ref = s.person_type_ref
    WHERE pt.type LIKE 'Z%';

-- Update tracking consultant

    UPDATE #p7m_contacts
    SET
      contract_consultant = pt.person_ref
      ,perm_team = s.team
      ,contract_team = s.team
      ,office = s.team
    FROM #p7m_contacts con
      INNER JOIN search_code sc ON contact_id = position_ref
      INNER JOIN staff s ON sc.code = s.resp_user_code
      INNER JOIN person_type pt ON s.person_type_ref = pt.person_type_ref
    WHERE search_type = 4
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars
                       WHERE [key] = 'contact_tracking_consultant_code_type')
      AND pt.type LIKE 'Z%';

-- Copy update perm consultant to contract consultant

    UPDATE #p7m_contacts
    SET perm_consultant = contract_consultant;

    CALL write_csv('contacts', csv_file_path);

----------------------------------------------------------------------------
-- Load data for CONTACT_INDUSTRY_SECTORS.CSV

    CALL logger('Load CONTACT_INDUSTRY_SECTORS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,contact_id AS [contact_id]
      ,code AS [industry]
    INTO #p7m_contact_industry_sectors
    FROM #p7m_contacts
      INNER JOIN search_code ON contact_id = position_ref
    WHERE search_type = 4
      AND code_type IN(SELECT [value_int] FROM #p7m_vars WHERE [key] = 'contact_industry_code_type');

    CALL write_csv('contact_industry_sectors', csv_file_path);

    DROP TABLE #p7m_contact_industry_sectors;

----------------------------------------------------------------------------
-- Load data for CONTACT_JOB_CATEGORIES.CSV

    CALL logger('Load CONTACT_JOB_CATEGORIES', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,contact_id AS [contact_id]
      ,code AS [job_category]
    INTO #p7m_contact_job_categories
    FROM #p7m_contacts
      INNER JOIN search_code ON contact_id = position_ref
    WHERE search_type = 4
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'contact_job_category_code_type');

    CALL write_csv('contact_job_categories', csv_file_path);

    DROP TABLE #p7m_contact_job_categories;

----------------------------------------------------------------------------
-- Load data for CONTACT_SKILLS.CSV

    CALL logger('Load CONTACT_SKILLS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,contact_id AS [contact_id]
      ,code AS [skill]
    INTO #p7m_contact_skills
    FROM #p7m_contacts
      INNER JOIN search_code ON contact_id = position_ref
    WHERE search_type = 4
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'contact_skill_code_type');

    CALL write_csv('contact_skills', csv_file_path);

    DROP TABLE #p7m_contact_skills;

----------------------------------------------------------------------------
-- Load data for CONTACT_LOCATIONS.CSV

    CALL logger('Load CONTACT_LOCATIONS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,contact_id AS [contact_id]
      ,code AS [location]
    INTO #p7m_contact_locations
    FROM #p7m_contacts
      INNER JOIN search_code ON contact_id = position_ref
     WHERE search_type = 4
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'contact_location_code_type');

    CALL write_csv('contact_locations', csv_file_path);

    DROP TABLE #p7m_contact_locations;

----------------------------------------------------------------------------
-- Load data for X_CLIENT_JOB.CSV

    CALL logger('Load X_CLIENT_JOB', log_file_path);

    SELECT DISTINCT
      CAST(NULL AS INT) AS [id]
      ,o.organisation_ref AS [client]
      ,rl.position_ref AS [contact]
      ,o.opportunity_ref AS [job]
    INTO #p7m_x_client_job
    FROM opportunity o
      INNER JOIN opport_role rl ON o.opportunity_ref = rl.opportunity_ref
    WHERE EXISTS (SELECT 1
                  FROM #p7m_vars
                  WHERE rl.role_type = [value]
                    AND [key] = 'job_contact_role_type')
      AND EXISTS (SELECT 1
                  FROM #client_list c
                  WHERE o.organisation_ref = c.organisation_ref)
      AND EXISTS (SELECT 1
                  FROM #p7m_contacts c
                  WHERE rl.position_ref = c.contact_id);

    UPDATE #p7m_x_client_job
    SET [id] = IDENTITY(10);

    CREATE UNIQUE INDEX p7m_x_client_job_idx ON #p7m_x_client_job (client, contact, job);

    CALL write_csv('x_client_job', csv_file_path);

----------------------------------------------------------------------------
-- Load data for CONTRACT_JOBS.CSV

    CALL logger('Load CONTRACT_JOBS', log_file_path);

    SELECT
      opp.opportunity_ref AS [job_id]
      ,LEFT(opp.create_timestamp, 10) AS [createddate]
      ,opp.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,opp.update_user AS [updated_by]
      ,a.address_line_1 AS [street1]
      ,a.address_line_2 AS [street2]
      ,a.address_line_3 AS [locality]
      ,a.post_town AS [town]
      ,a.county_state AS [county]
      ,a.zipcode AS [post_code]
      ,a.country_code AS [country]
      ,opp.no_persons_reqd AS [no_req]
      ,tv.hours_per_day AS [std_hours]
      ,tv.time_unit AS [pay_period]
      ,'N' AS [fixed_term]
      ,tv.rate1_invoice AS [chrg_rate]
      ,tv.rate1_payment AS [pay_rate]
      ,opp.record_status AS [status]
      ,opp.displayname AS [job_title]
      ,tv.start_date AS [start_dt]
      ,tv.end_date AS [end_date]
      ,opp.source AS [job_src]
      ,tv.working_for AS [report_to]
      ,opp.type AS [job_type]
      ,CAST(NULL AS CHAR(4)) AS [location_cd]
      ,opp.responsible_user AS [cons1]
      ,100 AS [cons1_perc]
      ,opp.record_status AS [close_reason]
      ,'N' AS [lead]
      ,opp.record_status AS [competitor]
      ,opp.date_closed AS [filled_dt]
      ,opp.responsible_user AS [consultant]
      ,opp.responsible_team AS [team]
      ,opp.responsible_team AS [office]
      ,REPLACE(REPLACE(opp.notes, '\x0d', ''), '\x0a', '') AS [personal_attributes]
    INTO #p7m_contract_jobs
    FROM opportunity opp
      INNER JOIN #p7m_x_client_job x ON opp.organisation_ref = x.client
                                    AND opp.opportunity_ref = x.job
      LEFT OUTER JOIN address a ON opp.address_ref = a.address_ref
      LEFT OUTER JOIN temporary_vac tv ON opp.opportunity_ref = tv.opportunity_ref
    WHERE opp.type IN(SELECT [value] FROM #p7m_vars WHERE [key] = 'job_contract_type')
     ;

    CREATE UNIQUE INDEX p7m_contract_jobs_idx ON #p7m_contract_jobs (job_id);

    UPDATE #p7m_contract_jobs
    SET
      j.location_cd = c.location_cd
    FROM #p7m_contract_jobs j
      INNER JOIN (SELECT
                    opportunity_ref
                    ,MAX(code) AS location_cd
                  FROM search_code sc
                    INNER JOIN #p7m_vars ON sc.code_type = [value_int]
                  WHERE sc.search_type = 5
                    AND [key] = 'job_location_code_type'
                  GROUP BY
                    opportunity_ref) c ON j.job_id = c.opportunity_ref;

    UPDATE #p7m_contract_jobs
    SET fixed_term = 'Y'
    FROM #p7m_contract_jobs j
    WHERE EXISTS (SELECT 1
                  FROM event e
                  WHERE type IN(SELECT [value]
                                FROM #p7m_vars WHERE [key] = 'job_contact_fee_event_type')
                    AND j.job_id = e.opportunity_ref);

    UPDATE #p7m_contract_jobs
    SET lead = 'Y'
    WHERE close_reason IN(SELECT [value]
                          FROM #p7m_vars WHERE [key] = 'job_lead_record_status_code');

    UPDATE #p7m_contract_jobs
    SET close_reason = NULL
    WHERE close_reason NOT IN(SELECT [value]
                              FROM #p7m_vars WHERE [key] = 'job_close_reason_type');

    UPDATE #p7m_contract_jobs
    SET competitor = NULL
    WHERE competitor NOT IN(SELECT [value]
                            FROM #p7m_vars WHERE [key] = 'job_competitor_type');

----------------------------------------------------------------------------
-- Load data for CONTRACT_JOB_INDUSTRY_SECTORS.CSV

    CALL logger('Load CONTRACT_JOB_INDUSTRY_SECTORS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [industry]
    INTO #p7m_contract_job_industry_sectors
    FROM #p7m_contract_jobs
      INNER JOIN search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_industry_code_type');

    CALL write_csv('contract_job_industry_sectors', csv_file_path);

    DROP TABLE #p7m_contract_job_industry_sectors;

----------------------------------------------------------------------------
-- Load data for CONTRACT_JOB_JOB_CATEGORIES.CSV

    CALL logger('Load CONTRACT_JOB_JOB_CATEGORIES', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [job_category]
    INTO #p7m_contract_job_job_categories
    FROM #p7m_contract_jobs
      INNER JOIN search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_job_category_code_type');

    CALL write_csv('contract_job_job_categories', csv_file_path);

----------------------------------------------------------------------------
-- Load data for CONTRACT_JOB_QUALIFICATIONS.CSV

    CALL logger('Load CONTRACT_JOB_QUALIFICATIONS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [qual]
    INTO #p7m_contract_job_qualifications
    FROM #p7m_contract_jobs
      INNER JOIN search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_qualification_code_type');

    CALL write_csv('contract_job_qualifications', csv_file_path);

    DROP TABLE #p7m_contract_job_qualifications;

----------------------------------------------------------------------------
-- Load data for CONTRACT_JOB_SKILLS.CSV

    CALL logger('Load CONTRACT_JOB_SKILLS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [skill]
    INTO #p7m_contract_job_skills
    FROM #p7m_contract_jobs
      INNER JOIN  search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_skill_code_type');

    CALL write_csv('contract_job_skills', csv_file_path);

    DROP TABLE #p7m_contract_job_skills;

----------------------------------------------------------------------------
-- Load data for PERM_JOBS.CSV

    CALL logger('Load PERM_JOBS', log_file_path);

    SELECT
      opp.opportunity_ref AS [job_id]
      ,LEFT(opp.create_timestamp, 10) AS [createddate]
      ,opp.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,opp.update_user AS [updated_by]
      ,a.address_line_1 AS [street1]
      ,a.address_line_2 AS [street2]
      ,a.address_line_3 AS [locality]
      ,a.post_town AS [town]
      ,a.county_state AS [county]
      ,a.zipcode AS [post_code]
      ,a.country_code AS [country]
      ,opp.record_status AS [status]
      ,opp.displayname AS [job_title]
      ,opp.date_opened AS [start_dt]
      ,opp.source AS [job_src]
      ,opp.type AS [job_type]
      ,opp.date_closed AS [closed_dt]
      ,CAST(NULL AS CHAR(4)) AS [location_cd]
      ,opp.responsible_user AS [cons1]
      ,100 AS [cons1_perc]
      ,opp.record_status AS [close_reason]
      ,'N' AS [lead]
      ,opp.record_status AS [competitor]
      ,opp.date_closed AS [filled_dt]
      ,opp.responsible_user AS [consultant]
      ,opp.responsible_team AS [team]
      ,opp.responsible_team AS [office]
      ,pv.agreed_fee AS [fee_perc]
      ,pv.lower_income AS [sal_from]
      ,pv.upper_income AS [sal_to]
      ,'N' AS [fixed_term]
      ,opp.date_opened AS [open_since]
      ,CAST(NULL AS CHAR(4)) AS [educ_level]
      ,opp.no_persons_reqd AS [no_req]
      ,REPLACE(REPLACE(opp.notes, '\x0d', ''), '\x0a', '') AS [personal_attributes]
    INTO #p7m_perm_jobs
    FROM opportunity opp
      INNER JOIN #p7m_x_client_job x ON opp.organisation_ref = x.client
                                    AND opp.opportunity_ref = x.job
      LEFT OUTER JOIN address a ON opp.address_ref = a.address_ref
      LEFT OUTER JOIN permanent_vac pv ON opp.opportunity_ref = pv.opportunity_ref
    WHERE opp.type IN(SELECT [value]
                      FROM #p7m_vars WHERE [key] = 'job_perm_type')
     ;

    CREATE UNIQUE INDEX p7m_perm_jobs_idx ON #p7m_perm_jobs (job_id);

    UPDATE #p7m_perm_jobs
    SET
      j.location_cd = c.location_cd
      ,j.educ_level = c.educ_level
    FROM #p7m_perm_jobs j
      INNER JOIN (SELECT
                    opportunity_ref
                    ,MAX(CASE [key] WHEN 'job_location_code_type' THEN code END) AS location_cd
                    ,MAX(CASE [key] WHEN 'job_education_code_type' THEN code END) AS educ_level
                  FROM search_code sc
                    INNER JOIN #p7m_vars ON sc.code_type = [value_int]
                  WHERE sc.search_type = 5
                    AND [key] IN('job_location_code_type', 'job_education_code_type')
                  GROUP BY
                    opportunity_ref) c ON j.job_id = c.opportunity_ref;

    UPDATE #p7m_perm_jobs
    SET fixed_term = 'Y'
    FROM #p7m_perm_jobs j
    WHERE EXISTS (SELECT 1
                  FROM event e
                  WHERE type IN(SELECT [value] FROM #p7m_vars WHERE [key] = 'job_contact_fee_event_type')
                    AND j.job_id = e.opportunity_ref);

    UPDATE #p7m_perm_jobs
    SET lead = 'Y'
    WHERE close_reason IN(SELECT [value]
                          FROM #p7m_vars WHERE [key] = 'job_lead_record_status_code');

    UPDATE #p7m_perm_jobs
    SET close_reason = NULL
    WHERE close_reason NOT IN(SELECT [value]
                              FROM #p7m_vars WHERE [key] = 'job_close_reason_type');

    UPDATE #p7m_perm_jobs
    SET competitor = NULL
    WHERE competitor NOT IN(SELECT [value]
                            FROM #p7m_vars WHERE [key] = 'job_competitor_type');

----------------------------------------------------------------------------
-- Load data for PERM_JOB_INDUSTRY_SECTORS.CSV

    CALL logger('Load PERM_JOB_INDUSTRY_SECTORS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [industry]
    INTO #p7m_perm_job_industry_sectors
    FROM #p7m_perm_jobs
      INNER JOIN search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_industry_code_type');

    CALL write_csv('perm_job_industry_sectors', csv_file_path);

    DROP TABLE #p7m_perm_job_industry_sectors;

----------------------------------------------------------------------------
-- Load data for PERM_JOB_JOB_CATEGORIES.CSV

    CALL logger('Load PERM_JOB_JOB_CATEGORIES', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [job_category]
    INTO #p7m_perm_job_job_categories
    FROM #p7m_perm_jobs
      INNER JOIN search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_job_category_code_type');

    CALL write_csv('perm_job_job_categories', csv_file_path);

    DROP TABLE #p7m_perm_job_job_categories;

----------------------------------------------------------------------------
-- Load data for PERM_JOB_QUALIFICATIONS.CSV

    CALL logger('Load PERM_JOB_QUALIFICATIONS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [qual]
    INTO #p7m_perm_job_qualifications
    FROM #p7m_perm_jobs
      INNER JOIN search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_qualification_code_type');

    CALL write_csv('perm_job_qualifications', csv_file_path);

    DROP TABLE #p7m_perm_job_qualifications;

----------------------------------------------------------------------------
-- Load data for PERM_JOB_SKILLS.CSV

    CALL logger('Load PERM_JOB_SKILLS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,job_id AS [job_id]
      ,code AS [skill]
    INTO #p7m_perm_job_skills
    FROM #p7m_perm_jobs
      INNER JOIN search_code ON job_id = opportunity_ref
    WHERE search_type = 5
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'job_skill_code_type');

    CALL write_csv('perm_job_skills', csv_file_path);

    DROP TABLE #p7m_perm_job_skills;

----------------------------------------------------------------------------
-- Load data for SHORTLIST.CSV

    CALL logger('Load SHORTLIST', log_file_path);

    SELECT
      e.opportunity_ref
      ,can.person_ref
      ,MAX(e.event_ref) AS last_event_ref
      ,MIN(e.event_ref) AS first_event_ref
      ,MAX(CASE WHEN e.type IN('KE03', 'Q21')
           THEN e.event_ref END) AS last_cv_event_ref
      ,MAX(CASE WHEN e.type IN('Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
           THEN e.event_ref END) AS last_interview_event_ref
      ,MAX(CASE WHEN e.type IN('F', 'H')
           THEN e.event_ref END) AS last_offer_event_ref
      ,MAX(CASE WHEN e.type IN('F', 'H') AND e.outcome = 'F1'
           THEN e.event_ref END) AS last_rejected_offer_event_ref
      ,MAX(CASE WHEN e.type IN('KE03', 'Q21', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
                           AND e.outcome = 'A4'
           THEN e.event_ref END) AS last_rejected_event_ref
    INTO #shortlist_dates
    FROM event e
      INNER JOIN event_role can ON e.event_ref = can.event_ref
    WHERE e.type IN('A', 'F', 'H', 'KE03', 'Q21', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
      AND can.type IN('A','1', 'D', 'F', 'H', 'K')
      AND (e.opportunity_ref IN(SELECT job_id FROM #p7m_contract_jobs) OR
           e.opportunity_ref IN(SELECT job_id FROM #p7m_perm_jobs))
    GROUP BY
      e.opportunity_ref
      ,can.person_ref;

    CREATE UNIQUE INDEX shortlist_dates_idx ON #shortlist_dates (opportunity_ref, person_ref);

    SELECT
      MIN(e.event_ref) AS [shortlist_id]
      ,e.opportunity_ref AS job_id
      ,e.organisation_ref AS client_id
      ,can.person_ref AS candidate_id
      ,con.person_ref AS person_id
      ,MIN(e.create_timestamp) AS [createddate]
      ,MAX(CASE WHEN e.event_ref = first_event_ref THEN e.create_user END) AS [created_by]
      ,MAX(CASE WHEN e.event_ref = first_event_ref THEN cons.person_ref END) AS [perm_consultant]
      ,MAX(CASE WHEN e.event_ref = first_event_ref THEN cons.team END) AS [perm_team]
      ,MAX(CASE WHEN e.event_ref = first_event_ref THEN cons.person_ref END) AS [contract_consultant]
      ,MAX(CASE WHEN e.event_ref = first_event_ref THEN cons.team END) AS [contract_team]
      ,MAX(CASE WHEN e.event_ref = first_event_ref THEN cons.team END) AS [office]
      ,MIN(e.event_date) AS [date_short]
      ,MIN(e.event_time) AS [time_short]
      ,MAX(CASE WHEN e.event_ref = last_event_ref
                THEN CASE WHEN e.type IN('F', 'H') AND e.outcome = 'F3'
                            THEN 'Offer Accepted'
                          WHEN e.type IN('F', 'H') AND e.outcome = 'F1'
                            THEN 'Offer Rejected'
                          WHEN e.type IN('KE03', 'Q21', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
                           AND e.outcome = 'A4'
                            THEN 'Rejected'
                          WHEN e.type IN('A')
                            THEN 'Shortlisted'
                          WHEN e.type IN('F', 'H')
                            THEN 'Under Offer'
                          WHEN e.type IN('KE03', 'Q21')
                            THEN 'CV Sent'
                          WHEN e.type IN('Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
                            THEN 'Interview Arranged'
                          END
                END) AS [status]
      ,MIN(CASE e.event_ref WHEN last_cv_event_ref THEN e.event_date END) AS [last_cv_dt]
      ,MIN(CASE e.event_ref WHEN last_cv_event_ref THEN e.event_time END) AS [last_cv_tm]
      ,MIN(CASE e.event_ref WHEN last_interview_event_ref THEN e.event_date END) AS [last_iv_dt]
      ,MIN(CASE e.event_ref WHEN last_interview_event_ref THEN e.event_time END) AS [last_iv_tm]
      ,MIN(CASE e.event_ref WHEN last_cv_event_ref THEN e.create_user END) AS [last_cv_by]
      ,MIN(CASE e.event_ref WHEN last_interview_event_ref THEN e.create_user END) AS [last_iv_by]
      ,MIN(CASE e.event_ref WHEN last_offer_event_ref
                            THEN create_timestamp END) AS [last_of_dt]
      ,MIN(CASE e.event_ref WHEN last_offer_event_ref
                            THEN CAST(create_timestamp AS TIME) END) AS [last_of_tm]
      ,MIN(CASE e.event_ref WHEN last_offer_event_ref THEN e.create_user END) AS [last_of_by]
      ,MAX(pla.income) AS [offer_sal]
      ,MIN(CASE e.event_ref WHEN last_rejected_offer_event_ref THEN e.outcome_date END) AS [rej_of_dt]
      ,MIN(CASE e.event_ref WHEN last_rejected_offer_event_ref
                            THEN CAST(update_timestamp AS TIME) END) AS [rej_of_tm]
      ,MIN(CASE e.event_ref WHEN last_rejected_offer_event_ref THEN e.create_user END) AS [rej_of_by]
      ,MIN(CASE e.event_ref WHEN last_rejected_event_ref THEN e.outcome_date END) AS [rej_dt]
      ,MIN(CASE e.event_ref WHEN last_rejected_event_ref
                            THEN CAST(update_timestamp AS TIME) END) AS [rej_tm]
      ,MIN(CASE e.event_ref WHEN last_rejected_event_ref THEN e.create_user END) AS [rej_by]
      ,MIN(CASE e.event_ref WHEN last_interview_event_ref THEN e.type END) AS [last_iv_st]
      ,MAX(CASE WHEN e.event_ref = last_event_ref
                 AND e.type IN('KE03', 'Q21', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
                 AND e.outcome = 'A4'
                THEN 'Agency' END) AS [rejected_by]
      ,MAX(CASE WHEN e.event_ref = last_event_ref
                 AND e.type IN('KE03', 'Q21', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
                 AND e.outcome = 'A4'
                THEN 'Would Consider for Future' END) AS [rejected_res]
      ,MAX(CASE WHEN e.event_ref = last_event_ref
                THEN CASE WHEN e.type IN('F', 'H') AND e.outcome = 'F3'
                            THEN 'Offer Accepted'
                          WHEN e.type IN('F', 'H') AND e.outcome = 'F1'
                            THEN 'Offer Rejected'
                          WHEN e.type IN('KE03', 'Q21', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
                           AND e.outcome = 'A4'
                            THEN 'Rejected'
                          WHEN e.type IN('A')
                            THEN 'Shortlisted'
                          WHEN e.type IN('F', 'H')
                            THEN 'Under Offer'
                          WHEN e.type IN('KE03', 'Q21')
                            THEN 'CV Sent'
                          WHEN e.type IN('Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
                            THEN 'Interview Arranged'
                          END
                END) AS [progress]
      ,MIN(CASE e.event_ref WHEN last_offer_event_ref THEN cons.person_ref END) AS [accepted_by]
      ,MIN(CASE e.event_ref WHEN last_offer_event_ref THEN e.outcome_date END) AS [acc_off_date]
      ,MIN(CASE e.event_ref WHEN last_offer_event_ref
                            THEN CAST(e.outcome_date AS DATETIME) END) AS [acc_off_time]
    INTO #p7m_shortlist
    FROM event e
      INNER JOIN event_role can ON e.event_ref = can.event_ref
      INNER JOIN event_role con ON e.event_ref = con.event_ref
      INNER JOIN event_role cons ON e.event_ref = cons.event_ref
      LEFT OUTER JOIN placing pla ON e.event_ref = pla.event_ref
      INNER JOIN #shortlist_dates fle ON e.opportunity_ref = fle.opportunity_ref
                                     AND can.person_ref = fle.person_ref
    WHERE e.type IN('A', 'F', 'H', 'KE03', 'Q21', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35', 'Q36')
      AND can.type IN('A', '1', 'D', 'F', 'H', 'K')
      AND con.type IN('C1')
      AND cons.type IN('UC1')
    GROUP BY
      e.opportunity_ref
      ,con.person_ref
      ,e.organisation_ref
      ,can.person_ref;

    CREATE UNIQUE INDEX p7m_shortlist_idx
                     ON #p7m_shortlist (shortlist_id, candidate_id, job_id);

    CALL write_csv('shortlist', csv_file_path);

----------------------------------------------------------------------------
-- Load data for X_SHORT_CAND.CSV

    CALL logger('Load X_SHORT_CAND', log_file_path);

    SELECT
      sl.shortlist_id AS [id]
      ,sl.shortlist_id AS [shortlist]
      ,sl.job_id AS [job]
      ,sl.candidate_id AS [candidate]
      ,con.contact_id AS [contact]
      ,sl.client_id AS [client]
    INTO #p7m_x_short_cand
    FROM #p7m_shortlist sl
      INNER JOIN #p7m_contacts con ON sl.person_id = con.person_id;

    CALL write_csv('x_short_cand', csv_file_path);

    DROP TABLE #p7m_x_short_cand;

----------------------------------------------------------------------------
-- Load data for CANDIDATES.CSV

    CALL logger('Load CANDIDATES', log_file_path);

    SELECT
      per.person_ref AS [candidate_id]
      ,per.create_timestamp AS [createddate]
      ,per.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,per.update_user AS [updated_by]
      ,a.address_line_1 AS [street1]
      ,a.address_line_2 AS [street2]
      ,a.address_line_3 AS [locality]
      ,a.post_town AS [town]
      ,a.county_state AS [county]
      ,a.zipcode AS [post_code]
      ,a.country_code AS [country]
      ,'N' AS [hot]
      ,per.source AS [source]
      ,ISNULL(ptp.status, ptc.status) AS [status]
      ,CASE WHEN NULLIF(canp.notice_period, 0) IS NOT NULL
            THEN canp.notice_period || ' ' || canp.notice_period_mode
            END AS [not_period]
      ,CASE per.own_car WHEN 'Y' THEN 'Y' ELSE NULL END AS [own_trans]
      ,CAST(NULL AS CHAR(4)) AS [high_edu_lev]
      ,CASE WHEN ptp.type IS NOT NULL AND ptc.type IS NOT NULL
            THEN CASE WHEN canc.income_required IS NOT NULL
                      THEN ptc.type
                      ELSE ptp.type END
            ELSE ISNULL(ptp.type, ptc.type)
            END AS [def_role]
      ,ISNULL(canp.date_available, canc.date_available) AS [avail_from]
      ,per.user_date1 AS [visa_exp]
      ,per.cv_last_updated AS [cv_received]
      ,per.nationality AS [visa_type]
      ,CASE per.sole_agency WHEN 'Y' THEN 'Y' ELSE NULL END AS [ex_clusive]
      ,CASE per.do_not_mailshot WHEN 'Y' THEN 'N' ELSE 'Y' END AS [e_shot]
      ,CASE WHEN ptp.type IS NOT NULL AND ptc.type IS NOT NULL
            THEN CASE WHEN canc.income_required IS NOT NULL
                      THEN ptc.type || ', ' || ptp.type
                      ELSE ptp.type END
            ELSE ISNULL(ptp.type, ptc.type)
            END AS [cand_type]
      ,CASE canc.part_time WHEN 'Y' THEN 'Y' ELSE NULL END AS [part_time]
      ,canc.income_required AS [rate_req]
      ,canp.income_required AS [salary_req]
      ,canp.package_value_reqd AS [ote_req]
      ,CASE WHEN ptp.type IS NOT NULL
            THEN 'Y'
            END AS [p_perm]
      ,CASE WHEN ptc.type IS NOT NULL AND canc.income_required IS NOT NULL
            THEN 'Y'
            END AS [p_contr]
      ,CASE per.discretion_reqd WHEN 'Y' THEN 'Y' ELSE NULL END AS [relocate]
      ,ptp.notes AS [look_for]
      ,per.email_address AS [home_email]
      ,pos.email_address AS [work_email]
      ,per.responsible_user AS [perm_consultant]
      ,per.responsible_team AS [perm_team]
      ,per.responsible_user AS [contract_consultant]
      ,per.responsible_team AS [contract_team]
      ,per.responsible_team AS [office]
      ,per.title AS [title]
      ,per.first_name AS [first_name]
      ,per.last_name AS [last_name]
      ,per.first_name || ' ' || last_name AS [fullname]
      ,per.first_name AS [salutation]
      ,per.initials AS [initials]
      ,a.telephone_number AS [home_tel_number]
      ,ISNULL(TRIM(day_telno), TRIM(pos.telephone_number)) AS [work_tel_number]
      ,pos.telephone_ext AS [work_extension]
      ,per.mobile_telno AS [mobile_tel_number]
      ,REPLACE(REPLACE(REPLACE(LTRIM(ISNULL(a.notes, '') + ' '
         + ISNULL(ptp.notes, '') + ' '
         + ISNULL(ptc.notes, '')), '  ', ' '), '\x0d', '')
         , '\x0a', '') AS [notes]
    INTO #p7m_candidates
    FROM person per
      LEFT OUTER JOIN person_type ptp ON per.person_ref = ptp.person_ref AND ptp.type = 'C'
      LEFT OUTER JOIN person_type ptc ON per.person_ref = ptc.person_ref AND ptc.type = 'A'
      LEFT OUTER JOIN candidate canp ON ptp.person_type_ref = canp.person_type_ref
      LEFT OUTER JOIN candidate canc ON ptc.person_type_ref = canc.person_type_ref
      LEFT OUTER JOIN address a ON per.person_ref = a.person_ref
        AND a.create_timestamp = (SELECT ISNULL(MAX(CASE WHEN main_address = 'Y' AND type = 'HOME'
                                                         THEN create_timestamp
                                                         END), MAX(create_timestamp))
                                  FROM address a1
                                  WHERE a.person_ref = a1.person_ref)
        AND a.main_address = 'Y'
        AND a.type = 'HOME'
      LEFT OUTER JOIN position pos ON per.person_ref = pos.person_ref
        AND pos.position_ref
          = (SELECT
               CASE MAX(CASE record_status WHEN 'C' THEN position_ref END) WHEN 0
                    THEN MAX(CASE record_status WHEN 'C' THEN position_ref END)
                    ELSE MAX(CASE WHEN record_status != 'C' THEN position_ref END)
                    END
             FROM position pos_last
             WHERE pos.person_ref = pos_last.person_ref)
    WHERE EXISTS (SELECT 1
                  FROM person_type pts
                  WHERE pts.type IN('A', 'C')
                    AND per.person_ref = pts.person_ref)
      AND per.person_ref IN(SELECT candidate_id FROM #p7m_shortlist)
    ;

    CREATE UNIQUE INDEX p7m_candidates_idx ON #p7m_candidates (candidate_id);

    UPDATE #p7m_candidates
    SET
      can.high_edu_lev = c.high_edu_lev
    FROM #p7m_candidates can
      INNER JOIN (SELECT
                    person_ref
                    ,MAX(code) AS high_edu_lev
                  FROM search_code sc
                    INNER JOIN #p7m_vars ON sc.code_type = [value_int]
                  WHERE sc.search_type = 1
                    AND [key] = 'candidate_education_code_type'
                  GROUP BY
                    person_ref) c ON can.candidate_id = c.person_ref;

    UPDATE #p7m_candidates
    SET hot = 'Y'
    FROM #p7m_candidates c
    WHERE EXISTS (SELECT 1
                  FROM  search_code sc
                  WHERE code_type IN(SELECT [value]
                                     FROM #p7m_vars WHERE [key] = 'candidate_hot_code_type')
                    AND code IN(SELECT [value]
                                FROM #p7m_vars WHERE [key] = 'candidate_hot_code')
                    AND c.candidate_id = sc.person_ref);


    UPDATE #p7m_candidates
    SET
      can.perm_consultant = pt.person_ref
      ,can.contract_consultant = pt.person_ref
      ,can.office = s.team
    FROM #p7m_candidates can
      INNER JOIN search_code sc ON candidate_id = person_ref
      INNER JOIN staff s ON sc.code = s.resp_user_code
      INNER JOIN person_type pt ON pt.person_type_ref = s.person_type_ref
    WHERE search_type = 1
      AND code_type = 1055
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'candidate_tracking_consultant_code_type');
      AND pt.type LIKE 'Z%';

    CALL write_csv('candidates', csv_file_path);

----------------------------------------------------------------------------
-- Load data for CANDIDATE_INDUSTRY_SECTORS.CSV

    CALL logger('Load CANDIDATE_INDUSTRY_SECTORS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,candidate_id AS [candidate_id]
      ,code AS [industry]
    INTO #p7m_candidate_industry_sectors
    FROM #p7m_candidates
      INNER JOIN search_code ON candidate_id = person_ref
    WHERE search_type = 1
      AND code_type IN(SELECT [value_int] FROM #p7m_vars WHERE [key] = 'candidate_industry_code_type');

    CALL write_csv('candidate_industry_sectors', csv_file_path);

    DROP TABLE #p7m_candidate_industry_sectors;

----------------------------------------------------------------------------
-- Load data for CANDIDATE_JOB_CATEGORIES.CSV

    CALL logger('Load CANDIDATE_JOB_CATEGORIES', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,candidate_id AS [candidate_id]
      ,code AS [job_category]
    INTO #p7m_candidate_job_categories
    FROM #p7m_candidates
      INNER JOIN search_code ON candidate_id = person_ref
    WHERE search_type = 1
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'candidate_job_category_code_type');

    CALL write_csv('candidate_job_categories', csv_file_path);

    DROP TABLE #p7m_candidate_job_categories;

----------------------------------------------------------------------------
-- Load data for CANDIDATE_LOCATIONS.CSV

    CALL logger('Load CANDIDATE_LOCATIONS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,candidate_id AS [candidate_id]
      ,code AS [location]
    INTO #p7m_candidate_locations
    FROM #p7m_candidates
      INNER JOIN search_code ON candidate_id = person_ref
    WHERE search_type = 1
      AND code_type IN(SELECT [value_int] FROM #p7m_vars WHERE [key] = 'candidate_location_code_type');

    CALL write_csv('candidate_locations', csv_file_path);

    DROP TABLE #p7m_candidate_locations;

----------------------------------------------------------------------------
-- Load data for CANDIDATE_QUALIFICATIONS.CSV

    CALL logger('Load CANDIDATE_QUALIFICATIONS', log_file_path);

    SELECT
      CAST(NULL AS INT) AS [id]
      ,candidate_id AS [candidate_id]
      ,code AS [qual]
    INTO #p7m_candidate_qualifications
    FROM #p7m_candidates
      INNER JOIN search_code ON candidate_id = person_ref
    WHERE search_type = 1
      AND code_type IN(SELECT [value_int]
                       FROM #p7m_vars WHERE [key] = 'candidate_qualification_code_type');

    INSERT INTO #p7m_candidate_qualifications
    SELECT
      CAST(NULL AS INT) AS [id]
      ,c.candidate_id
      ,CAST(YEAR(p.date_of_birth) AS VARCHAR)
    FROM #p7m_candidates c
      INNER JOIN person p ON c.candidate_id = p.person_ref
    WHERE p.date_of_birth IS NOT NULL;

    UPDATE #p7m_candidate_qualifications
    SET id = IDENTITY(10);

    CALL write_csv('candidate_qualifications', csv_file_path);

    DROP TABLE #p7m_candidate_qualifications;

----------------------------------------------------------------------------
-- Load data for CANDIDATE_SKILLS.CSV

    CALL logger('Load CANDIDATE_SKILLS', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,candidate_id AS [candidate_id]
      ,code AS [skill]
    INTO #p7m_candidate_skills
    FROM #p7m_candidates
      INNER JOIN search_code ON candidate_id = person_ref
    WHERE search_type = 1
      AND code_type IN(SELECT [value_int] FROM #p7m_vars WHERE [key] = 'candidate_skill_code_type');

    CALL write_csv('candidate_skills', csv_file_path);

    DROP TABLE #p7m_candidate_skills;

----------------------------------------------------------------------------
-- Load data for CANDIDATE_PREV_ASSIGN.CSV

    CALL logger('Load CANDIDATE_PREV_ASSIGN', log_file_path);

    SELECT
      pos.position_ref AS [prev_assign_id]
      ,pos.person_ref AS [candidate_id]
      ,pos.create_timestamp AS [createddate]
      ,pos.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,pos.update_user AS [updated_by]
      ,pe.income AS [salary]
      ,pos.record_status AS [status]
      ,pos.start_date AS [start_date]
      ,pos.end_date AS [end_date]
      ,pos.displayname AS [job_title]
      ,pos.type AS [assig_type]
      ,CASE WHEN rs.[key] IS NOT NULL THEN org.displayname END AS [prev_co]
      ,org.organisation_ref AS prev_co_id
      ,mgr.displayname AS [prv_manager]
      ,mpos.position_ref AS prv_manager_id
      ,ISNULL(mpos.telephone_number, a.telephone_number) AS [prv_man_tel]
      ,REPLACE(REPLACE(pos.notes, '\x0d', ' '), '\x0a', ' ') AS [notes]
      ,te.hours_details AS [pay_rate]
      ,ISNULL(s.team, pos.responsible_team) AS [office]
    INTO #p7m_candidate_prev_assign
    FROM position pos
      INNER JOIN person per ON pos.person_ref = per.person_ref
      LEFT OUTER JOIN person_type pt ON pos.person_ref = per.person_ref AND pt.type LIKE 'Z%'
      LEFT OUTER JOIN staff s ON pt.person_type_ref = s.person_type_ref
      LEFT OUTER JOIN permanent_emp pe ON pos.position_ref = pe.position_ref
      LEFT OUTER JOIN temporary_emp te ON pos.position_ref = te.position_ref
      LEFT OUTER JOIN organisation org ON pos.organisation_ref = org.organisation_ref
      LEFT OUTER JOIN person mgr ON pos.manager_person_ref = mgr.person_ref
      LEFT OUTER JOIN position mpos ON mgr.person_ref = mpos.person_ref
                         AND mpos.contact_status IN(SELECT [value]
                                                    FROM #p7m_vars
                                                    WHERE [key] = 'contact_contact_status_code')
                         AND mpos.record_status IN(SELECT [value]
                                                   FROM #p7m_vars
                                                   WHERE [key] = 'contact_record_status_code')
      LEFT OUTER JOIN address a ON pos.address_ref = a.address_ref
      LEFT OUTER JOIN #p7m_vars rs ON org.record_status = rs.[value]
                                  AND rs.[key] ='client_employer_only_record_status_code'
    WHERE pos.organisation_ref IN(SELECT client_id FROM #p7m_clients)
      AND pos.person_ref IN(SELECT candidate_id FROM #p7m_candidates);

    CREATE INDEX candidate_prev_assign_idx ON #p7m_candidate_prev_assign (candidate_id);

    CALL write_csv('candidate_prev_assign', csv_file_path);

----------------------------------------------------------------------------
-- Load data for CONTACT_PREV_ASSIGN.CSV

    CALL logger('Load CCONTACT_PREV_ASSIGN', log_file_path);

    SELECT
      pos.position_ref AS [prev_assign_id]
      ,pos.position_ref AS [candidate_id]
      ,pos.create_timestamp AS [createddate]
      ,pos.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,pos.update_user AS [updated_by]
      ,pe.income AS [salary]
      ,pos.record_status AS [status]
      ,pos.start_date AS [start_date]
      ,pos.end_date AS [end_date]
      ,pos.displayname AS [job_title]
      ,pos.type AS [assig_type]
      ,org.displayname AS [prev_co]
      ,org.organisation_ref AS prev_co_id
      ,mgr.displayname AS [prv_manager]
      ,mpos.position_ref AS prv_manager_id
      ,ISNULL(mpos.telephone_number, a.telephone_number) AS [prv_man_tel]
      ,REPLACE(REPLACE(pos.notes, '\x0d', ' '), '\x0a', ' ') AS [notes]
      ,te.hours_details AS [pay_rate]
      ,ISNULL(s.team, pos.responsible_team) AS [office]
    INTO #p7m_contact_prev_assign
    FROM position pos
      INNER JOIN person per ON pos.person_ref = per.person_ref
      LEFT OUTER JOIN person_type pt ON pos.person_ref = per.person_ref AND pt.type LIKE 'Z%'
      LEFT OUTER JOIN staff s ON pt.person_type_ref = s.person_type_ref
      LEFT OUTER JOIN permanent_emp pe ON pos.position_ref = pe.position_ref
      LEFT OUTER JOIN temporary_emp te ON pos.position_ref = te.position_ref
      LEFT OUTER JOIN organisation org ON pos.organisation_ref = org.organisation_ref
      LEFT OUTER JOIN person mgr ON pos.manager_person_ref = mgr.person_ref
      LEFT OUTER JOIN position mpos ON mgr.person_ref = mpos.person_ref
                         AND mpos.contact_status IN(SELECT [value]
                                                    FROM #p7m_vars
                                                    WHERE [key] = 'contact_contact_status_code')
                         AND mpos.record_status IN(SELECT [value]
                                                   FROM #p7m_vars
                                                   WHERE [key] = 'contact_record_status_code')
      LEFT OUTER JOIN address a ON pos.address_ref = a.address_ref
    WHERE pos.organisation_ref IN(SELECT client_id FROM #p7m_clients)
      AND pos.position_ref IN(SELECT contact_id FROM #p7m_contacts);

    CREATE INDEX contact_prev_assign_idx ON #p7m_contact_prev_assign (candidate_id);

    CALL write_csv('contact_prev_assign', csv_file_path);

----------------------------------------------------------------------------
-- Load data for X_PA_CLIENT.CSV

    CALL logger('Load X_PA_CLIENT', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,prev_assign_id AS [prev_assign]
      ,prv_manager_id AS [contact]
      ,prev_co_id AS [client]
    INTO #p7m_x_pa_client
    FROM #p7m_candidate_prev_assign
    WHERE prev_co_id IN(SELECT client_id FROM #p7m_clients)
      AND status NOT IN(SELECT [value] FROM #p7m_vars
                        WHERE [key] = 'client_employer_only_record_status_code');

    CALL write_csv('x_pa_client', csv_file_path);

    DROP TABLE #p7m_x_pa_client;

----------------------------------------------------------------------------
-- Load data for X_PREV_ASSIG_CAND.CSV

    CALL logger('Load X_PREV_ASSIG_CAND', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,prev_assign_id AS [assignment]
      ,candidate_id AS [candidate]
    INTO #p7m_x_prev_assig_cand
    FROM #p7m_candidate_prev_assign;

    CALL write_csv('x_prev_assig_cand', csv_file_path);

    DROP TABLE #p7m_x_prev_assig_cand;

----------------------------------------------------------------------------
-- Load data for X_CLIENT_SUB.CSV

    CALL logger('Load X_CLIENT_SUB', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,client_id AS [client]
      ,parent_id AS [parent]
    INTO #p7m_x_client_sub
    FROM #p7m_clients
    WHERE parent_id IS NOT NULL;

    CALL write_csv('x_client_sub', csv_file_path);

    DROP TABLE #p7m_x_client_sub;

----------------------------------------------------------------------------
-- Load data for X_LE_CLIENT.CSV

    CALL logger('Load X_LE_CLIENT', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,le_id AS [le]
      ,client_id AS [client]
    INTO #p7m_x_le_client
    FROM #p7m_clients
    WHERE parent_id IS NOT NULL;

    CALL write_csv('x_le_client', csv_file_path);

    DROP TABLE #p7m_x_le_client;

----------------------------------------------------------------------------
-- Load data for PERM_ASSIGN.CSV

    CALL logger('Load PERM_ASSIGN', log_file_path);

    SELECT
      MAX(e.event_ref) AS assignment_id
      ,MAX(CASE e.type WHEN '1PA' THEN e.create_timestamp END) AS createddate
      ,MAX(CASE e.type WHEN '1PA' THEN e.create_user END) AS created_by
      ,GETDATE() AS updateddate
      ,MAX(CASE e.type WHEN '1PA' THEN e.update_user END) AS updated_by
      ,MAX(CASE e.type WHEN '1PA' THEN inv.amnt1 END) AS salary
      ,MAX(CASE e.type WHEN '1PA' THEN inv.netamnt END) AS fee
      ,MAX(CASE e.type WHEN 'F' THEN plc.start_date END) AS start_dt
      ,MAX(cons.person_ref) AS cons1
      ,100 AS cons1_perc
      ,MAX(CASE e.type WHEN '1PA' THEN inv.feepc END) AS fee_pec
      ,'Current' AS status
      ,opp.displayname AS job_title
      ,'Pemanent Placement' AS assig_type
      ,opp.date_closed AS filled_dt
      ,MAX(CASE e.type WHEN '1PA' THEN cons.person_ref END) AS consultant
      ,MAX(CASE e.type WHEN '1PA' THEN cons.team END) AS team
      ,MAX(CASE e.type WHEN '1PA' THEN cons.team END) AS office
      ,opp.opportunity_ref AS job_id
      ,can.person_ref AS candidate_id
    INTO #perm_assign_temp
    FROM opportunity opp
      INNER JOIN event e ON opp.opportunity_ref = e.opportunity_ref
      INNER JOIN event_role can ON e.event_ref = can.event_ref
      INNER JOIN event_role cons ON e.event_ref = cons.event_ref
      LEFT OUTER JOIN u_v5invoice inv ON e.event_ref = inv.event_ref
      LEFT OUTER JOIN placing plc ON e.event_ref = plc.event_ref
    WHERE opp.opportunity_ref IN(SELECT job_id FROM #p7m_perm_jobs)
      AND can.person_ref IN(SELECT candidate_id FROM #p7m_candidates)
      AND (e.type = '1PA' OR (e.type = 'F' AND e.outcome = 'F3'))
      AND e.outcome != 'DEL'
      AND can.type IN('A','1', 'D', 'F', 'H', 'K')
      AND cons.type IN('UC1')
    GROUP BY
      opp.opportunity_ref
      ,can.person_ref
      ,opp.displayname
      ,opp.date_closed
    HAVING SUM(CASE e.type WHEN 'F' THEN 1 ELSE 0 END) > 0
      AND SUM(CASE e.type WHEN '1PA' THEN 1 ELSE 0 END) > 0;

    SELECT DISTINCT
      assignment_id AS [assignment_id]
      ,createddate AS [createddate]
      ,created_by AS [created_by]
      ,updateddate AS [updateddate]
      ,updated_by AS [updated_by]
      ,salary AS [salary]
      ,fee AS [fee]
      ,start_dt AS [start_dt]
      ,cons1 AS [cons1]
      ,cons1_perc AS [cons1_perc]
      ,fee_pec AS [fee_pec]
      ,status AS [status]
      ,job_title AS [job_title]
      ,assig_type AS [assig_type]
      ,filled_dt AS [filled_dt]
      ,consultant AS [consultant]
      ,team AS [team]
      ,office AS [office]
    INTO #p7m_perm_assign
    FROM #perm_assign_temp;

    CALL write_csv('perm_assign', csv_file_path);

    DROP TABLE #p7m_perm_assign;

-----------------------------------------------------------------------------
-- Load data for CONTR_ASSIGN.CSV

    CALL logger('Load CONTR_ASSIGN', log_file_path);

    SELECT
      e.event_ref AS assignment_id
      ,e.create_timestamp AS createddate
      ,e.create_user AS created_by
      ,GETDATE() AS updateddate
      ,e.update_user AS updated_by
      ,'Current' AS status
      ,tb.start_date AS start_dt
      ,tb.end_date AS end_dt
      ,cons.person_ref AS cons1
      ,100 AS cons1_perc
      ,opp.displayname AS job_title
      ,'Contract Placement' AS assig_type
      ,opp.date_closed AS filled_dt
      ,tv.start_date AS orig_start
      ,tb.hours_per_day AS std_hours
      ,5 AS std_days
      ,jc.job_category AS prim_jcat_aw
      ,'Y' AS exempt_aw
      ,'Standard Contract' AS cont_type
      ,tb.rate1_invoice - tb.rate1_payment AS margin_val
      ,CASE WHEN tb.rate1_invoice > 0
            THEN (tb.rate1_invoice - tb.rate1_payment) / tb.rate1_invoice
            END AS margin_pcnt
      ,tb.time_unit AS pay_period
      ,tb.rate1_payment AS chrg_rate
      ,tb.rate1_invoice AS pay_rate
      ,cons.person_ref AS consultant
      ,cons.team AS team
      ,cons.team AS office
      ,opp.opportunity_ref AS job_id
      ,can.person_ref AS candidate_id
    INTO #contr_assign_temp
    FROM opportunity opp
      INNER JOIN event e ON opp.opportunity_ref = e.opportunity_ref
      LEFT OUTER JOIN temporary_vac tv ON opp.opportunity_ref = tv.opportunity_ref
      LEFT OUTER JOIN (SELECT job_id, MIN(job_category) AS job_category
                       FROM #p7m_contract_job_job_categories
                       GROUP BY job_id) jc ON opp.opportunity_ref = jc.job_id
      INNER JOIN event_role can ON e.event_ref = can.event_ref
      INNER JOIN event_role cons ON e.event_ref = cons.event_ref
      LEFT OUTER JOIN temporary_booking tb ON e.event_ref = tb.event_ref
    WHERE opp.opportunity_ref IN(SELECT job_id FROM #p7m_contract_jobs)
      AND can.person_ref IN(SELECT candidate_id FROM #p7m_candidates)
      AND e.type = 'H'
      AND e.outcome = 'F3'
      AND can.type IN('A','1', 'D', 'F', 'H', 'K')
      AND cons.type IN('UC1');

    SELECT DISTINCT
      assignment_id AS [assignment_id]
      ,createddate AS [createddate]
      ,created_by AS [created_by]
      ,updateddate AS [updateddate]
      ,updated_by AS [updated_by]
      ,status AS [status]
      ,start_dt AS [start_dt]
      ,end_dt AS [end_dt]
      ,cons1 AS [cons1]
      ,cons1_perc AS [cons1_perc]
      ,job_title AS [job_title]
      ,assig_type AS [assig_type]
      ,filled_dt AS [filled_dt]
      ,orig_start AS [orig_start]
      ,std_hours AS [std_hours]
      ,std_days AS [std_days]
      ,prim_jcat_aw AS [prim_jcat_aw]
      ,exempt_aw AS [exempt_aw]
      ,cont_type AS [cont_type]
      ,margin_val AS [margin_val]
      ,margin_pcnt AS [margin_pcnt]
      ,pay_period AS [pay_period]
      ,chrg_rate AS [chrg_rate]
      ,pay_rate AS [pay_rate]
      ,consultant AS [consultant]
      ,team AS [team]
      ,office AS [office]
    INTO #p7m_contr_assign
    FROM #contr_assign_temp;

    CALL write_csv('contr_assign', csv_file_path);

    DROP TABLE #p7m_contr_assign;
    DROP TABLE #p7m_contract_job_job_categories;

---------------------------------------------------------------------------
-- Load data for X_ASSIG_CAND.CSV

    CALL logger('Load X_ASSIG_CAND', log_file_path);

    SELECT
      CAST(NULL AS INT) AS [id]
      ,assignment_id AS [assignment]
      ,job_id AS [job]
      ,candidate_id AS [candidate]
    INTO #p7m_x_assig_cand
    FROM #perm_assign_temp;

    INSERT INTO #p7m_x_assig_cand
    SELECT
      CAST(NULL AS INT) AS [id]
      ,assignment_id AS [assignment]
      ,job_id AS [job]
      ,candidate_id AS [candidate]
    FROM #contr_assign_temp;

    UPDATE #p7m_x_assig_cand
    SET [id] = IDENTITY(10);

    CALL write_csv('x_assig_cand', csv_file_path);

    DROP TABLE #p7m_x_assig_cand;
    DROP TABLE #perm_assign_temp;
    DROP TABLE #contr_assign_temp;

----------------------------------------------------------------------------
-- Load data for INTERVIEWS.CSV

    CALL logger('Load INTERVIEWS', log_file_path);

    SELECT
      e.event_ref AS [interview_id]
      ,e.create_timestamp AS [createddate]
      ,e.create_user AS [created_by]
      ,GETDATE() AS [updateddate]
      ,e.update_user AS [updated_by]
      ,a.address_line_1 AS [street1]
      ,a.address_line_2 AS [street2]
      ,a.address_line_3 AS [locality]
      ,a.post_town AS [town]
      ,a.county_state AS [county]
      ,a.zipcode AS [post_code]
      ,a.country AS [country]
      ,con.position_ref AS [iv_cont]
      ,e.type AS [stage]
      ,e.event_date AS [iv_date]
      ,e.event_time AS [iv_start]
      ,CASE WHEN e.duration IS NULL
            THEN CAST(DATEADD(HOUR, 1, e.event_time) AS DATETIME)
            ELSE CAST(DATEADD(MINUTE, MINUTE(e.duration),
                      DATEADD(HOUR, HOUR(e.duration), e.event_time)) AS DATETIME)
            END AS [iv_end]
      ,CAST(NULL AS CHAR(1)) AS [iv_att]
      ,er_cons.team AS [int_office]
      ,CASE WHEN e.type IN('Q13', 'Q15') THEN 'Y' ELSE 'N' END AS [internal]
      ,er_cons.person_ref AS [int_cons]
      ,er_cons.person_ref AS [perm_consultant]
      ,er_cons.team AS [perm_team]
      ,er_cons.person_ref AS [contract_consultant]
      ,er_cons.team AS [contract_team]
      ,er_cons.team AS [office]
      ,e.opportunity_ref AS job_id
      ,er_can.person_ref AS candidate_id
    INTO #p7m_interviews
    FROM event e
      INNER JOIN event_role er_can ON e.event_ref = er_can.event_ref
      INNER JOIN event_role er_con ON e.event_ref = er_con.event_ref
      INNER JOIN position con ON er_con.person_ref = con.person_ref
                             AND er_con.organisation_ref = con.organisation_ref
      INNER JOIN event_role er_cons ON e.event_ref = er_cons.event_ref
      LEFT OUTER JOIN address a ON con.address_ref = a.address_ref
    WHERE e.type IN('Q13','Q15','Q31','Q32','Q33','Q34','Q35','Q36')
      AND er_can.type IN('A','1','D','F','H','K')
      AND er_con.type IN('C1')
      AND er_cons.type IN('U1')
      AND EXISTS (SELECT 1
                  FROM position p
                  WHERE p.person_ref = con.person_ref
                    AND p.organisation_ref = con.organisation_ref
                  GROUP BY
                    person_ref
                    ,organisation_ref
                  HAVING
                    CASE SUM(CASE record_status WHEN 'C' THEN 1 ELSE 0 END)
                      WHEN 0 THEN MAX(position_ref)
                      ELSE MAX(CASE record_status WHEN 'C' THEN position_ref END)
                      END = con.position_ref)
      AND EXISTS (SELECT 1
                  FROM #p7m_clients
                  WHERE con.organisation_ref = client_id)
      AND EXISTS (SELECT 1
                  FROM #p7m_contacts
                  WHERE con.position_ref = contact_id)
      AND EXISTS (SELECT 1
                  FROM #p7m_candidates
                  WHERE er_can.person_ref = candidate_id)
    ;

    CREATE UNIQUE INDEX p7m_interviews_idx
                     ON #p7m_interviews (interview_id, candidate_id, job_id);

    UPDATE #p7m_interviews
    SET iv_att = 'Y'
    WHERE interview_id IN(SELECT last_interview_event_ref FROM #shortlist_dates);

    SELECT *
    INTO #p7m_ext_interviews
    FROM #p7m_interviews
    WHERE internal = 'N';

    CALL write_csv('ext_interviews', csv_file_path);
    DROP TABLE #p7m_ext_interviews;

    SELECT *
    INTO #p7m_int_interviews
    FROM #p7m_interviews
    WHERE internal = 'Y';

    CALL write_csv('int_interviews', csv_file_path);
    DROP TABLE #p7m_int_interviews;

----------------------------------------------------------------------------
-- Load data for X_SHORT_IV.CSV

    CALL logger('Load X_SHORT_IV', log_file_path);

    SELECT
      IDENTITY(10) AS [id]
      ,sl.shortlist_id AS [shortlist]
      ,iv.interview_id AS [interview]
    INTO #p7m_x_short_iv
    FROM #p7m_interviews iv
      INNER JOIN #p7m_shortlist sl ON iv.candidate_id = sl.candidate_id
                                  AND iv.job_id = sl.job_id;

    CALL write_csv('x_short_iv', csv_file_path);

    DROP TABLE #p7m_x_short_iv;
    DROP TABLE #p7m_interviews;
    DROP TABLE #p7m_shortlist;

----------------------------------------------------------------------------
-- Load data for JOURNALS

    CALL logger('Load GENERAL_JOURNALS',log_file_path);

    SELECT
      e.event_ref AS [journal_id]
      ,e.event_date AS [datetime]
      ,cons.person_ref AS [consultant]
      ,can.person_ref AS [candidate]
      ,c.contact_id AS [contact]
      ,e.organisation_ref AS [client]
      ,e.opportunity_ref AS [job]
      ,con.person_ref AS [person]
      ,lu.description || ': ' || REPLACE(REPLACE(e.notes, '\x0d', ''), '\x0a', '') AS [notes]
      ,jc.[key] AS [journal_type]
      ,e.outcome
    INTO #journals
    FROM event e
      INNER JOIN lookup lu ON e.type = lu.code
      INNER JOIN #p7m_vars jc ON e.type = jc.value
      LEFT OUTER JOIN event_role can ON e.event_ref = can.event_ref
                                    AND can.type IN('A', '1', 'D', 'F', 'H', 'K')
      LEFT OUTER JOIN event_role con ON e.event_ref = con.event_ref
                                    AND con.type = 'C1'
      LEFT OUTER JOIN event_role cons ON e.event_ref = cons.event_ref
                                     AND cons.type = 'U1'
      LEFT OUTER JOIN #p7m_contacts c ON con.person_ref = c.person_id
    WHERE lu.code_type = 123
      AND jc.[key] IN('journal_general_type', 'journal_send_email_type',
                      'journal_call_made_log_type','journal_client_visit_type',
                      'journal_internal_interview_arranged_type')
      AND (e.organisation_ref IS NULL OR
           e.organisation_ref IN(SELECT client_id FROM #p7m_clients))
      AND (can.person_ref IS NULL OR
           can.person_ref IN(SELECT candidate_id FROM #p7m_candidates))
      AND (e.opportunity_ref IS NULL OR
           e.opportunity_ref IN(SELECT job_id FROM #p7m_contract_jobs) OR
           e.opportunity_ref IN(SELECT job_id FROM #p7m_perm_jobs))
      AND ISNULL(e.organisation_ref, ISNULL(e.opportunity_ref, can.person_ref)) IS NOT NULL;

    SELECT
      CAST(NULL AS INT) AS [journal_id]
      ,[datetime]
      ,[consultant]
      ,[candidate]
      ,[contact]
      ,[client]
      ,[job]
      ,[notes]
    INTO #p7m_general_journals
    FROM #journals
    WHERE journal_type = 'journal_general_type'
      AND ISNULL(candidate, ISNULL(contact, ISNULL(client, job))) IS NOT NULL;

    INSERT INTO #p7m_general_journals
    SELECT DISTINCT
      NULL AS [journal_id]
      ,GETDATE() AS [datetime]
      ,NULL AS [consultant]
      ,[candidate]
      ,NULL AS [contact]
      ,NULL AS [client]
      ,NULL AS [job]
      ,'P7 Candidate Ref: ' || candidate AS [notes]
    FROM #journals
    WHERE journal_type = 'journal_general_type'
      AND candidate IS NOT NULL;

    INSERT INTO #p7m_general_journals
    SELECT DISTINCT
      NULL AS [journal_id]
      ,GETDATE() AS [datetime]
      ,NULL AS [consultant]
      ,NULL AS [candidate]
      ,[contact]
      ,NULL AS [client]
      ,NULL AS [job]
      ,'P7 Contact Ref: ' || person AS [notes]
    FROM #journals
    WHERE journal_type = 'journal_general_type'
      AND contact IS NOT NULL;

    INSERT INTO #p7m_general_journals
    SELECT DISTINCT
      NULL AS [journal_id]
      ,GETDATE() AS [datetime]
      ,NULL AS [consultant]
      ,NULL AS [candidate]
      ,NULL AS [contact]
      ,[client]
      ,NULL AS [job]
      ,'P7 Organisation Ref: ' || client AS [notes]
    FROM #journals
    WHERE journal_type = 'journal_general_type'
      AND client IS NOT NULL;

    INSERT INTO #p7m_general_journals
    SELECT DISTINCT
      NULL AS [journal_id]
      ,GETDATE() AS [datetime]
      ,NULL AS [consultant]
      ,NULL AS [candidate]
      ,NULL AS [contact]
      ,NULL AS [client]
      ,[job]
      ,'P7 Opportunity Ref: ' || job AS [notes]
    FROM #journals
    WHERE journal_type = 'journal_general_type'
      AND job IS NOT NULL;

    UPDATE #p7m_general_journals
    SET [journal_id] = IDENTITY(10);

    CALL logger('Load SEND_EMAIL_JOURNALS',log_file_path);

    SELECT
      [journal_id]
      ,[datetime]
      ,[consultant]
      ,[candidate]
      ,[contact]
      ,[client]
      ,[job]
      ,[notes]
    INTO #p7m_send_email_journals
    FROM #journals
    WHERE journal_type = 'journal_send_email_type';

    CALL write_csv('send_email_journals', csv_file_path);

    DROP TABLE #p7m_send_email_journals;

    CALL logger('Load CALL_MADE_LOG_JOURNALS',log_file_path);

    SELECT
      [journal_id]
      ,[datetime]
      ,[consultant]
      ,[candidate]
      ,[contact]
      ,[client]
      ,[job]
      ,[notes]
    INTO #p7m_call_made_log_journals
    FROM #journals
    WHERE journal_type = 'journal_call_made_log_type';

    CALL write_csv('call_made_log_journals', csv_file_path);

    DROP TABLE #p7m_call_made_log_journals;

    CALL logger('Load CLIENT_VISIT_ATTENDED_JOURNALS',log_file_path);

    SELECT
      [journal_id]
      ,[datetime]
      ,[consultant]
      ,[candidate]
      ,[contact]
      ,[client]
      ,[job]
      ,[notes]
    INTO #p7m_client_visit_attended_journals
    FROM #journals
    WHERE journal_type = 'journal_client_visit_type'
      AND outcome IS NOT NULL;

    CALL write_csv('client_visit_attended_journals', csv_file_path);

    DROP TABLE #p7m_client_visit_attended_journals;

    CALL logger('Load CLIENT_VISIT_ARRANGED_JOURNALS',log_file_path);

    SELECT
      [journal_id]
      ,[datetime]
      ,[consultant]
      ,[candidate]
      ,[contact]
      ,[client]
      ,[job]
      ,[notes]
    INTO #p7m_client_visit_arranged_journals
    FROM #journals
    WHERE journal_type = 'journal_client_visit_type';

    CALL write_csv('client_visit_arranged_journals', csv_file_path);

    DROP TABLE #p7m_client_visit_arranged_journals;

    CALL logger('Load INTERNAL_INTERVIEW_ARRANGED_JOURNALS',log_file_path);

    SELECT
      [journal_id]
      ,[datetime]
      ,[consultant]
      ,[candidate]
      ,[contact]
      ,[client]
      ,[job]
      ,[notes]
    INTO #p7m_internal_interview_arranged_journals
    FROM #journals
    WHERE journal_type = 'journal_interal_interview_arranged_type';

    CALL write_csv('internal_interview_arranged_journals', csv_file_path);

    DROP TABLE #p7m_internal_interview_arranged_journals;

----------------------------------------------------------------------------

-- Load data for PERM_LEAD_JOBS

    CALL logger('Load PERM_LEAD_JOBS', log_file_path);

    SELECT *
    INTO #p7m_perm_lead_jobs
    FROM #p7m_perm_jobs
    WHERE lead = 'Y';

    DELETE #p7m_perm_jobs
    WHERE lead = 'Y';

    CALL write_csv('perm_jobs', csv_file_path);
    CALL write_csv('perm_lead_jobs', csv_file_path);

    DROP TABLE #p7m_perm_jobs;
    DROP TABLE #p7m_perm_lead_jobs;

----------------------------------------------------------------------------

-- Load data for CONTRACT_LEAD_JOBS

    CALL logger('Load CONTRACT_LEAD_JOBS', log_file_path);

    SELECT *
    INTO #p7m_contract_lead_jobs
    FROM #p7m_contract_jobs
    WHERE lead = 'Y';

    DELETE #p7m_contract_jobs
    WHERE lead = 'Y';

    CALL write_csv('contract_jobs', csv_file_path);
    CALL write_csv('contract_lead_jobs', csv_file_path);

    DROP TABLE #p7m_contract_jobs;
    DROP TABLE #p7m_contract_lead_jobs;

----------------------------------------------------------------------------

-- Load data for DOCUMENTS

    CALL logger('Load DOCUMENTS', log_file_path);

    SELECT
      linkfile_ref AS [document_id]
      ,'P:\\p7nalive\\Linkfile\\'
        || UPPER(LEFT(parent_object_name, 8))
        || '\\'
        || REPLACE(TRIM(CASE MOD(LENGTH(parent_object_ref), 2) WHEN 0 THEN '0' ELSE '' END
        || SUBSTRING(parent_object_ref, 1, 1 + MOD(LENGTH(parent_object_ref), 2))
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 2 + MOD(LENGTH(parent_object_ref), 2), 2)
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 4 + MOD(LENGTH(parent_object_ref), 2), 2)
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 6 + MOD(LENGTH(parent_object_ref), 2), 2)
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 8 + MOD(LENGTH(parent_object_ref), 2), 2)
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 10 + MOD(LENGTH(parent_object_ref), 2), 2)
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 12 + MOD(LENGTH(parent_object_ref), 2), 2)
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 14 + MOD(LENGTH(parent_object_ref), 2), 2)
        || ' '
        || SUBSTRING(LEFT(parent_object_ref, LENGTH(parent_object_ref) - 1)
            , 16 + MOD(LENGTH(parent_object_ref), 2), 2))
           ,' ', '\\')
        || '\\'
        || parent_object_ref
        || '.'
        || linkfile_ref
        || '.DOC' AS [document_path]
      ,type AS [document_type]
      ,parent_object_ref AS [entity_reference]
      ,'DOC' AS [document_ext]
      ,displayname AS [document_description]
    INTO #p7m_documents
    FROM linkfile l
    WHERE type = 'WPC1'
      AND record_status = 'C'
      AND EXISTS (SELECT 1
                  FROM #p7m_candidates
                  WHERE l.parent_object_ref = candidate_id);

    CALL write_csv('documents', csv_file_path);

----------------------------------------------------------------------------
-- Create Documents Zip

    EXECUTE('UNLOAD SELECT TOP 2000 ''"'
      || zip_exe_path
      || '" a -tzip "'
      || csv_file_path
      || 'documents.zip" "'' || document_path || ''"'' '
      || ' FROM #p7m_documents'
      || ' TO ''' || csv_file_path
      || 'documents.bat'' '
      || ' FORMAT ASCII QUOTES off ESCAPES off');

    CALL logger('Create ZIP file', log_file_path);

    EXECUTE ('xp_cmdshell ''"' || csv_file_path || 'documents.bat" ''');

    DROP TABLE #p7m_documents;

----------------------------------------------------------------------------
-- Clean up

    CALL logger('Migration completed', log_file_path);

    IF OBJECT_ID('logger') > 0 THEN
      DROP PROCEDURE logger;
    END IF;

    IF OBJECT_ID('write_csv') > 0 THEN
      DROP PROCEDURE write_csv;
    END IF;

  END;

END;
