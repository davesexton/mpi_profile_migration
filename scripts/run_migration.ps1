$x = Get-Content 'C:\Projects\git\mpi_profile_migration\migration_ssis\migration_ssis\xmigration.dtsx'
$z = $x -Replace '_x0022_', '"'
$z > 'C:\Projects\git\mpi_profile_migration\migration_ssis\migration_ssis\xmigration.dtsx'
$log = & 'C:\Program Files\Microsoft SQL Server\100\DTS\Binn\DTExec.exe' /f 'C:\Projects\git\mpi_profile_migration\migration_ssis\migration_ssis\xmigration.dtsx'

$log > 'C:\Users\davesexton\Desktop\migration.log'
