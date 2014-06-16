$files = @(
@{f1 = 'i_perm_lead_jobs.csv'; f2 = '..\migration_output_prior\perm_jobs.csv'},
@{f1 = 'i_perm_jobs.csv'; f2 = '..\migration_output_prior\perm_lead_jobs.csv'},
@{f1 = 'i_contract_lead_jobs.csv'; f2 = '..\migration_output_prior\contract_jobs.csv'},
@{f1 = 'i_contract_jobs.csv'; f2 = '..\migration_output_prior\contract_lead_jobs.csv'}
)
foreach($file in $files) {
  Get-Content $file.f1 -ReadCount 1 | ? {$_ -Match '^"\d+".'} | % {
    $x = $_ -Replace '^"(\d+)",.*$', '$1'
    Select-String $file.f2 -Pattern "^`"$x`"" | % {
      New-Object PSObject -Property @{
        csv_file = $file.f1
        id = $_.Matches[0].Value.Trim('"')
      }
    }
  }
}
