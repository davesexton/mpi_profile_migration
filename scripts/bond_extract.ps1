$db_user = 'LBigg'
$db_password = 'Welcome123'
$db_server = '10.115.103.72'
$db_database = 'PageGroupNAProd'

$sql = @"
SELECT 'TABLE', 'SQL'
UNION ALL
SELECT 
  t.name
  ,'"' + REPLACE(' SELECT '
  + REPLACE(REPLACE(REPLACE((SELECT '''' + QUOTENAME(name, '"') + ''''  
                             FROM PageGroupNAProd.sys.columns c
                             WHERE c.object_id = t.object_id
                              AND system_type_id NOT IN(165, 241, 34)
                             FOR XML PATH('x')),
      '</x><x>', ','), '<x>', ''), '</x>', '')
  + ' UNION ALL SELECT '
  + REPLACE(
     REPLACE(
       REPLACE((SELECT name AS x  
                FROM PageGroupNAProd.sys.columns c
                WHERE c.object_id = t.object_id
                  AND system_type_id NOT IN(165, 241, 34)
                FOR XML PATH('')), 
          '</x><x>', '], ''"''), QUOTENAME(['),
      '<x>', 'QUOTENAME(['),
    '</x>', '], ''"'')') 
  + ' FROM PageGroupNAProd.dbo.'
  + t.name, '"', '""') + '"' AS sql 
FROM PageGroupNAProd.sys.tables t 
WHERE t.name IN(
'CODES','DOCUMENT_CATEGORIES','DOCUMENT_CATEGORY_GROUP',
'DOCUMENT_TYPE','DOCUMENTS','JOURNAL_ENTRIES',
'JOURNAL_NOTES','MD_NAMED_OCCS','PROP_ADDRESS',
'PROP_ASSESSMENTS','PROP_ASSIG_FEE','PROP_ASSIG_GEN',
'PROP_ASSIG_RATE','PROP_CAND_CONS','PROP_CAND_GEN',
'PROP_CAND_PAYROLL','PROP_CAND_PREF','PROP_CASSIG_GEN',
'PROP_CASSIG_RATE','PROP_CJOB_GEN','PROP_CJOB_RATE',
'PROP_CLIENT_BEN','PROP_CLIENT_GEN','PROP_COMP_AGENCY',
'PROP_CONSULTANTS','PROP_CONT_CONS','PROP_CONT_GEN',
'PROP_CONTACTS','PROP_EDU_ESTAB','PROP_EMPLOYEE_GEN',
'PROP_IND_SECT','PROP_IV_GEN','PROP_JOB_BEN',
'PROP_JOB_CAT','PROP_JOB_GEN','PROP_JOB_GROUP',
'PROP_LE_GEN','PROP_LEADJOB_GEN','PROP_LOCATIONS',
'PROP_MISC','PROP_OFFICE_GEN','PROP_OWN_CONS',
'PROP_OWN_OFFICE','PROP_PERSON_GEN','PROP_PJOB_FEE',
'PROP_PJOB_GEN','PROP_QUALS','PROP_REF_GENERAL',
'PROP_SAL_BAND','PROP_SHORT_GEN','PROP_SKILLS',
'PROP_TEAM_GEN','PROP_TELEPHONE','PROP_TJOB_GEN',
'PROP_TJOB_RATE','PROP_X_ADAPT_MULT','PROP_X_ASSIG_CAND',
'PROP_X_CAND_JOB','PROP_X_CAND_REFS','PROP_X_CANDS_DNA',
'PROP_X_CANDS_TA','PROP_X_CLIENT_CON','PROP_X_CLIENT_JOB',
'PROP_X_CLIENT_SUB','PROP_X_CLIENTS_DN','PROP_X_CLIENTS_TA',
'PROP_X_CON_CON','PROP_X_INT_CAND','PROP_X_INT_RES',
'PROP_X_LE_CLIENTS','PROP_X_LEAD_PERS','PROP_X_OFF_TEAM',
'PROP_X_OFFICE_USR','PROP_X_PA_CLIENT','PROP_X_REF_CLIENT',
'PROP_X_SHORT_CAND','PROP_X_SHORT_IV','PROP_X_TEAM_EMP'
)
"@

$x -

cd C:\Projects\git\mpi_profile_migration\automation\bond_csvs

$sql = $sql -Replace '"', '""'
bcp "$sql" QueryOut 'tables.csv' -S $db_server -U $db_user -P $db_password '-t,' -c -e "logs\error.log"


Import-Csv '.\tables.csv' | % {
    $sql = $_.SQL -Replace '"', '""'
    $name = "bond_na_$($_.TABLE.ToLower()).csv"
    bcp "$sql" QueryOut $name -S $db_server -U $db_user -P $db_password '-t,' -c -e "logs\error.log"

}
