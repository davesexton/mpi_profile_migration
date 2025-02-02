$source = '\\AMA-SR-PROF-10.US.MichaelPage.local\migration'
$target = '.\migration_csvs'
$zip = (Join-Path $target 'migration.zip')

Set-Alias sz "C:\Windows\7za.exe"

If(Test-Path $zip) {
    Remove-Item $zip
}

$files = Get-ChildItem -Path $source -Include *.log, *.csv, *.zip

$files | ? {$_.Extension -eq '.log'} | % {
    $temp = Join-path $target $_.Name
    Copy-Item $_.FullName $temp
    $log = Get-Content $temp
    $log = $log | % {
        New-Object PSObject -Property @{
            Start = [datetime](($_ -split ': ')[0])
            Name = ($_ -split ': ')[1].Trim()
        }
    }

}

if($log[-1].Name -eq 'Migration Completed') {
    $files | ? {$_.Extension -eq '.csv'} |% {
        $temp = Join-path $target $_.Name
        Copy-Item $_.FullName $temp
        $output = sz a -tzip "$zip" "$Temp" 2>&1

        if($output -contains 'Everything is Ok') {
            Write-Host "$($output -match 'Compressing') - OK"
        } else {
            Write-Host "$($output -match 'Compressing') - Failed" -ForegroundColor Yellow
        }
    }
} else {
  Exit
}

$report = 1..($log.count - 2) | % {

    if($log[$_].Name -Match '(?<=Load )[A-Z_]+') {
        $path = Join-Path $target "$($matches[0]).CSV"
        $count = @(Import-Csv $path).count.ToString()
    } else {
      $count = ''
    }

    $ts = New-TimeSpan -Start $log[$_].Start -End $log[$_ + 1].Start
    $ts = $ts.ToString() -Replace '^\d{2}:\d{2}:\d{2}$', '$0.0000000'

    New-Object PSObject -Property @{
        Action = $log[$_].Name
        Count = $count
        Start = $log[$_].Start.ToString().Split(' ')[1]
        End = $log[$_ + 1].Start.ToString().Split(' ')[1]
        Duration = $ts
    }
}

$report | Select-Object Action, Count, Duration, Start, End `
        | ft -AutoSize | Tee-Object -file (Join-Path $target 'transfer.log')

Write-Host 'Total run time: ' (New-TimeSpan -Start $log[0].Start -End $log[-1].Start).ToString()
Write-Host 'All done'

