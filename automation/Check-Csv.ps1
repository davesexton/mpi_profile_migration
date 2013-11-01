clear
$csv_dir = 'C:\Projects\git\mpi_profile_migration\automation\migration_csvs'


$header = @"
File:   {0}
Column: {1}
"@

$line = @"
  Column:   {0}
  Blank %:  {1:p2}
  Unique %:  {2:p2}
+------------------------------------------------+
"@

$csv_file = 'contacts.csv'
$csv = Import-Csv (Join-Path $csv_dir $csv_file)
$records = $csv.Count
Write-Host ($header -f $csv_file, $records)
$column_list = @($csv | gm -MemberType noteproperty)[1..3]
$column_hash = @{}

$column_list | % {$column_hash[$_] = @{}}

$csv[0..3] | % {
  $row = $_
  $column_list | %{

    if($row."$_" -ne '') {
      $column_hash[$_][$row."$_"] += 1
    }


  }
}
#$column_hash.getenumerator() |

exit
$column_list | % {

  $column = $_.Name
  $column_values = @{}
  $blank = @($csv | ?{$_."$column" -eq ''}).Count / $records
  $unique = @($csv | Select $column -unique ).Count / $records

  Write-Host ($line -f $column, $blank, $unique)
}



# (@($csv | Select-Object CONTACT_ID -Unique)[0..10] | % {$_.CONTACT_ID}) -Join ', '
# (@($csv | Select-Object E_SHOT -Unique)[0..10] | % {$_.E_SHOT}) -Join ', '
#$CSV | Group-Object CONTACT_ID | ? {$_.Count > 1}
#$x.getenumerator() | Select Value | Measure-Object -Sum
#($x.getenumerator() | Select -ExpandProperty Value | Measure-Object -Sum).sum
