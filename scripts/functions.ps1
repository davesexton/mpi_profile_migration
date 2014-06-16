function find_ref ($f,$p) {
    Get-Childitem -Filter *.csv -Path 'C:\migration' -Recurse | ? {
        $_.FullName -notmatch 'migration_runs' } |  ? {
        $_.Name -match [regex]::escape($f) } | 
        Select-String -Pattern "\b$($p)\b"  | 
    Group-Object Path | 
    select @{Name='Name'; Expression={$_.Name -Replace 'c:\\migration\\', ''}}, Count
}
function row_count ($f) {
    $c = 0; Get-Content $f -ReadCount 1000 | % {$c += $_.Length}; $c - 1
}