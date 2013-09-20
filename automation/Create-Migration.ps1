$tables = Get-ChildItem -Path .\migration_csvs -Filter *.csv

$tables | % {
    $headers = @(((Get-Content $_.FullName)[0] -Replace '"', '').ToLower() -split ',')
    $name = $_.name -Replace '\.csv', '' 
    $cmd = "rails g scaffold $($Name)"
        
    if($_.Name -Match '^X_') {
        for ($i=1; $i -lt $headers.Count; $i++) {
	        $headers[$i] = "$($headers[$i])_id"
        }
        $cmd = "rails g migration $Name"
    }
    
    for ($i=0; $i -lt $headers.Count; $i++) {
	   
       switch -Regex ($headers[$i]) 
       {
            'id$' {$headers[$i] = "$($headers[$i]):integer"}
            'notes' {$headers[$i] = "$($headers[$i]):text"}
            default {$headers[$i] = "$($headers[$i]):string"}  
       }
       
    }
        
    $headers = $headers -join ' '
    
    "$cmd $headers "

} | Out-File ..\..\mpi_profile_migration_model\script\migration.ps1 -Encoding ASCII 