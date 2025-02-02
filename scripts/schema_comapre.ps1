$path = 'schema\PageGroupNATest117-Schema.htm'

$temp = (Get-Content $path) -Join ' '
$temp = $temp -Replace '^.*<body>', ''
$temp = $temp -Replace '</body>.*$', ''
$temp = $temp -Replace " +\w+=(['][^']+[']|[`"][^`"]+[`"]|\w+)", ''
$temp = $temp -Replace "&nbsp;", ''
$temp = $temp -Replace "&", '&amp;'
$temp = "<root>$temp</root>"

$xml = [xml]($temp)



$xml.root.div | % {
    $h1 = $_.H1
    if($h1 -ne 'Properties') {
        $_.table.tr | % {
            if($_.td[0] -ne 'Property') {
                if($_.td[0] -ne '') {$p = $_.td[0]}
                New-Object PSObject -Property @{
                    field = "$($h1)/$p/$($_.td[1])($($_.td[3] -Replace '/$', ''))"
                    size = $_.td[4]
                    scale = $_.td[5]
                    source = 'old'
                }
            } 
        }
    }
} | Export-Csv 'schema\old.csv' -NoTypeInformation

$path = 'schema\PageGroupNAPreProd-Schema.csv'
gc $path | ? {$_ -cnotmatch '^Property|^$'} | % {
    if($_ -notmatch ',') {
        $h1 = $_
    } else {
        $x = $_ -Split ','
        if($_ -notmatch '^,') {$p = $x[0]} 
        New-Object PSObject -Property @{
            field = "$($h1)/$p/$($x[1])($($x[3]))"
            size = $x[4]
            scale = $x[5]
            source = 'new'
            
        }
    }
} | Export-Csv 'schema\new.csv' -NoTypeInformation
