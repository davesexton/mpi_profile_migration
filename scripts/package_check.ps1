$package = [xml](Get-Content 'C:\Projects\git\mpi_profile_migration\migration_ssis\migration_ssis\migration.dtsx')
$ns = [System.Xml.XmlNamespaceManager]($package.NameTable)
$ns.AddNamespace("DTS", "www.microsoft.com/SqlServer/Dts")
$ns.AddNamespace("SQLTask", "www.microsoft.com/SqlServer/Dts/Tasks/SQLTask")

# SQL Expressions
$nodes = $package.SelectNodes("//DTS:PropertyExpression[contains(@DTS:Name, 'SqlCommand')]", $ns)

$sqls = $nodes | % {

   New-Object PSObject -Property @{
        sql = $_.'#text'
        name = $_.name #-Replace '^\[([^\]]*)\].*$', '$1'
   }
}

$sqls |  ? {$_.sql -match '--\w+'} # -and $_.sql -notmatch "@\["}


exit
$x = Get-Content .\us.config
$x = $x | % {($_ -Split '=')[0]} | Sort-Object 
$x | % {
    $var = $_
    $v_count = @($sqls | ? {$_.sql  -match 'User::' + $var}).count
    $c_count = @($sqls | ? {$_.sql -match '--' + $var}).count
    New-Object PSObject -Property @{var = $var; var_count = $v_count; com_count = $c_count}
} | ft -AutoSize

# Variables
$nodes = $package.SelectNodes("//DTS:Variable", $ns)

$sqls = $nodes | % {

   New-Object PSObject -Property @{
        sql = $_.VariableValue.'#text'
        name = $_.SelectSingleNode("DTS:Property[@DTS:Name='ObjectName']", $ns).'#text' 
   }
}

$sqls |  ? {$_.sql -match "^[^']+'"}


exit


# SQL Statement
$nodes = $package.SelectNodes("//property[@name = 'SqlCommand']", $ns)

$sqls = $nodes | % {

   New-Object PSObject -Property @{
        sql = $_.'#text'
        name = $_.ParentNode.parentNode.name
   }
}

$sqls |  ? {$_.sql -match "event_ref"}


exit

$package = [xml](Get-Content 'C:\Projects\git\mpi_profile_migration\migration_ssis\migration_ssis\migration.dtsx')
$ns = [System.Xml.XmlNamespaceManager]($package.NameTable)
$ns.AddNamespace("DTS", "www.microsoft.com/SqlServer/Dts")
$ns.AddNamespace("SQLTask", "www.microsoft.com/SqlServer/Dts/Tasks/SQLTask")

$nodes = $package.SelectNodes("//SQLTask:SqlTaskData", $ns)

#$nodes = $package.SelectNodes("//DTS:Property[@SqlTask:SqlStatementSource]", $ns)


exit


