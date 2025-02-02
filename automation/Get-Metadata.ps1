if(!$args[0]) {
    'No file name'
    exit
}
if(!(Test-Path $args[0])) {
    'Invalid file name'
    exit
}

#$sql = @(Get-Content 'C:\Projects\migration\migration.sql')
$sql = @(Get-Content $args[0])
$sql = $sql.length..0 | % {$sql[$_]}
$results = @()
$sql | % {
    if($_ -Match 'INTO #p7m_(\w+)') {
        $table = $matches[1]
    }

    if($_ -Match 'AS \[([^\]]+)\]') {
        $results += New-Object PSObject -Property @{
            table = $table
            column = $matches[1]
        }

    }
}
$results = ($results.length - 1)..0 | % {$results[$_]}
$results = $results | ? {$_.table -ne 'vars' -and $_.table -ne 'meta' -and $_.table -ne 'codes'}
#$results | % {
#    "    INSERT INTO #p7m_meta VALUES('$($_.table)',`n      '$($_.column)'`n    );"
#}

$results | Group-Object table | % {
    #$table = $_.Name
    #($results | ? {$_.Table -eq $table} | % {$_.column}) -Join ','

    #$_.Group | % {$_.Column}

    $columns = $(($_.Group | % {$_.Column}) -Join ',') `
        -Replace '[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,', ('$0' + "' ||`n      '")

    "    INSERT INTO #p7m_meta VALUES('$($_.Name)', `n      '$($columns)');`n`n"

}
