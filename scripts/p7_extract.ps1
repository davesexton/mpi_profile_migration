$P7_UNLOAD_PATH = 'c:\dxs\'
$REMOTE_CSV_PATH = '\\10.240.104.51\dxs\'
$LOCAL_CSV_PATH = 'C:\Projects\git\mpi_profile_migration\automation\import_csvs\'

$P7_USER = 'kimknight'
$P7_PASSWORD = 'kimknight'
$P7_SERVER = '10.240.104.51'
$P7_DATABASE = 'devsrsysql21'

$MIG_USER = 'migration'
$MIG_PASSWORD = 'm1grat10n'
$MIG_SERVER = '10.240.104.71\MIGRATION'
$MIG_DATABASE = 'migration'

# Live connections
#$REMOTE_CSV_PATH = '\\ama-sr-prof-10.us.michaelpage.local\dxs\'
#$P7_SERVER = 'ama-sr-prof-10.us.michaelpage.local'
#$P7_DATABASE = 'p7nalive'

$con_string = @'
uid={0};
pwd={1};
commlinks=SharedMemory,TCPIP{{Host={2}}};
enginename={3};
Driver={{Adaptive Server Anywhere 9.0}};
'@

$extract_sql = @"
UNLOAD {0} TO '{1}{2}.csv' 
FORMAT ASCII QUOTES off ESCAPES on
"@

$tables = @()
$tables += New-Object PSObject -Property @{
name = 'address'
sql = @"
SELECT
  address_ref
  ,person_ref
  ,organisation_ref
  ,type
  ,main_address
  ,address_line_1
  ,address_line_2
  ,address_line_3
  ,post_town
  ,county_state
  ,zipcode
  ,country
  ,country_code
  ,telephone_number
  ,fax_number
  ,email_address
  ,notes
  ,create_timestamp
  ,update_timestamp
  ,record_status 
FROM address
WHERE address_ref > 0
"@
}
$tables += New-Object PSObject -Property @{
name = 'candidate'
sql = @"
SELECT
  person_type_ref
  ,income_required
  ,notice_period
  ,notice_period_mode
  ,date_available
  ,part_time
  ,package_value_reqd 
FROM candidate
"@
}
$tables += New-Object PSObject -Property @{
name = 'event'
sql = @"
SELECT
  event_ref
  ,opportunity_ref
  ,event_date
  ,event_time
  ,duration
  ,type
  ,notes
  ,create_timestamp
  ,create_user
  ,update_timestamp
  ,update_user
  ,record_status
  ,organisation_ref
  ,outcome
  ,outcome_date
  ,position_ref 
FROM event
WHERE type IN('A','F','H','KE03','Q21','Q11','Q14','P15','KA1','G','P13','Q31','Q32','1PA',
              'Q33','Q34','Q35','Q36','KE01','P05','KA2','P11','KD2','P14','Q13','Q15')
"@
}
$tables += New-Object PSObject -Property @{
name = 'event_role'
sql = @"
SELECT
  event_ref
  ,person_ref
  ,type
  ,team
FROM event_role
WHERE event_role_ref > 0  
  AND type IN('A1','1','D','F','H','K','C1','C2','U1','UC1')
  AND person_ref IS NOT NULL
  AND event_ref IN(SELECT event_ref
                   FROM event
                   WHERE type IN('A','F','H','KE03','Q21','Q11','Q14','P15','KA1','G','P13','Q31','Q32','1PA',
                                 'Q33','Q34','Q35','Q36','KE01','P05','KA2','P11','KD2','P14','Q13','Q15'))
"@
}
$tables += New-Object PSObject -Property @{
name = 'linkfile'
sql = @"
SELECT
  linkfile_ref
  ,parent_object_name
  ,parent_object_ref
  ,displayname
  ,type
  ,update_timestamp
  ,record_status
FROM linkfile
WHERE linkfile_ref > 0
  AND (
    (type IN('WPC4','WPC5','WPC6','WPC7','WPC8','WPCO','WPC1','WPC2','WPC3') --candidate_document_type
      AND record_status = 'C' --candidate_current_document_record_status
      AND parent_object_name = 'person')
    OR (parent_object_name = 'organisation')
    OR (parent_object_name = 'opportunity'
      AND type NOT IN('HTJA') --job_web_advert_document_type
      )
    OR (parent_object_name = 'person'
      AND type IN('WCON','PPT','Y','WDOC','XLS','WSIG','Y12','Y13') --contact_document_type
      )
  )
"@
}
$tables += New-Object PSObject -Property @{
name = 'lookup'
sql = @"
SELECT
  code_type
  ,code
  ,description
FROM lookup
WHERE code_type = 123
"@
}
$tables += New-Object PSObject -Property @{
name = 'opport_role'
sql = @"
SELECT
  opportunity_ref
  ,person_ref
  ,role_type
  ,position_ref 
FROM opport_role
WHERE role_type IN('C1') --job_contact_role_type
 AND opportunity_ref IN(SELECT opportunity_ref
                        FROM profile.event
                        WHERE type IN('Q11','Q14','P15','KA1','G,P13','KE01','P05','KA2','P11','KD2','P14','Q13','Q15'))
"@
}
$tables += New-Object PSObject -Property @{
name = 'opportunity'
sql = @"
SELECT
  opportunity_ref
  ,organisation_ref
  ,address_ref
  ,displayname
  ,no_persons_reqd
  ,type
  ,source
  ,notes
  ,date_opened
  ,date_closed
  ,responsible_user
  ,responsible_team
  ,create_timestamp
  ,create_user
  ,update_timestamp
  ,update_user
  ,record_status
FROM opportunity
"@
}
$tables += New-Object PSObject -Property @{
name = 'organisation'
sql = @"
SELECT
  organisation_ref
  ,parent_organ_ref
  ,name
  ,displayname
  ,source
  ,notes
  ,responsible_user
  ,responsible_team
  ,create_timestamp
  ,create_user
  ,update_timestamp
  ,update_user
  ,record_status
  ,financial_year_end
  ,type
  ,web_site_url 
FROM organisation
"@
}
$tables += New-Object PSObject -Property @{
name = 'permanent_emp'
sql = @"
SELECT
  position_ref
  ,income
FROM permanent_emp
"@
}
$tables += New-Object PSObject -Property @{
name = 'permanent_vac'
sql = @"
SELECT
  opportunity_ref
  ,lower_income
  ,upper_income
  ,agreed_fee 
FROM permanent_vac
"@
}
$tables += New-Object PSObject -Property @{
name = 'person'
sql = @"
SELECT
  person_ref
  ,last_name
  ,first_name
  ,title
  ,initials
  ,displayname
  ,mobile_telno
  ,email_address
  ,date_of_birth
  ,nationality
  ,source
  ,responsible_user
  ,responsible_team
  ,create_timestamp
  ,create_user
  ,update_timestamp
  ,update_user
  ,record_status
  ,own_car
  ,sole_agency
  ,discretion_reqd
  ,cv_last_updated
  ,user_date1
  ,day_telno
  ,do_not_mailshot 
FROM person
"@
}
$tables += New-Object PSObject -Property @{
name = 'person_type'
sql = @"
SELECT
  person_type_ref
  ,person_ref
  ,type
  ,status
  ,notes
FROM person_type
WHERE type != 'D'
"@
}
$tables += New-Object PSObject -Property @{
name = 'placing'
sql = @"
SELECT
  event_ref
  ,start_date
  ,income
FROM placing
"@
}
$tables += New-Object PSObject -Property @{
name = 'position'
sql = @"
SELECT
  position_ref
  ,person_ref
  ,organisation_ref
  ,address_ref
  ,start_date
  ,end_date
  ,displayname
  ,manager_person_ref
  ,type
  ,telephone_number
  ,telephone_ext
  ,fax_number
  ,email_address
  ,contact_status
  ,notes
  ,responsible_user
  ,responsible_team
  ,create_timestamp
  ,create_user
  ,update_timestamp
  ,update_user
  ,record_status
  ,mobile_telno
  ,do_not_mailshot
FROM position
"@
}
$tables += New-Object PSObject -Property @{
name = 'search_code'
sql = @"
SELECT
  search_code_ref
  ,person_ref
  ,organisation_ref
  ,opportunity_ref
  ,position_ref
  ,search_type
  ,code_type
  ,code
FROM search_code
"@
}
$tables += New-Object PSObject -Property @{
name = 'staff'
sql = @"
SELECT
   staff_ref
  ,person_type_ref
  ,team
  ,resp_user_code
FROM staff
"@
}
$tables += New-Object PSObject -Property @{
name = 'temporary_booking'
sql = @"
SELECT 
  event_ref
  ,start_date
  ,end_date
  ,rate1_payment
  ,rate1_invoice
  ,time_unit
  ,hours_per_day
FROM temporary_booking
"@
}
$tables += New-Object PSObject -Property @{
name = 'temporary_emp'
sql = @"
SELECT
  position_ref
  ,hours_details 
FROM temporary_emp
"@
}
$tables += New-Object PSObject -Property @{
name = 'temporary_vac'
sql = @"
SELECT
  opportunity_ref
  ,start_date
  ,end_date
  ,working_for
  ,rate1_payment
  ,rate1_invoice
  ,time_unit
  ,hours_per_day
FROM temporary_vac
"@
}
$tables += New-Object PSObject -Property @{
name = 'u_v5invoice'
sql = @"
SELECT
  event_ref
  ,amnt1
  ,feepc
  ,netamnt 
FROM u_v5invoice
"@
}

$con_string = $con_string -f $P7_USER, $P7_PASSWORD, $P7_SERVER, $P7_DATABASE
$total_start_time = (Get-Date)

$tables | ? {$_.name -eq 'event_role'} | % {
  $start_time = (Get-Date)

  $sql = $extract_sql -f $_.sql, $P7_UNLOAD_PATH, $_.name

  dbisql -nogui -c $con_string "$sql"

  Copy-Item "$($REMOTE_CSV_PATH)$($_.name).csv" $LOCAL_CSV_PATH 
  
  sqlcmd -S $MIG_SERVER -U $MIG_USER -P $MIG_PASSWORD -Q "TRUNCATE TABLE $($MIG_DATABASE).profile.$($_.name)"
  
  bcp "$($MIG_DATABASE).profile.$($_.name)" in "$($LOCAL_CSV_PATH)$($_.name).csv" -S $MIG_SERVER -U $MIG_USER -P $MIG_PASSWORD '-t,' -c -e "logs\$($_.name)_error.log"
  
  "$($_.Name.ToUpper()) - $(New-Timespan -Start $start_time -End (Get-Date))"
}
"FINISHED - $(New-Timespan -Start $total_start_time -End (Get-Date))"