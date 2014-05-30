$file = $args[0]
$magic = 4

$i = 0
gc $file -Readcount 1 | % {
  $line = $_
  if($i -eq 0) 
  {
    1..$magic | % {$line | Set-Content ($file -Replace '\.csv', "_$($_).csv")}
  } 
  else 
  {  
    $line | Add-Content ($file -Replace '\.csv', "_$($i).csv")
  }
  $i += 1
  if($i -gt $magic) {$i = 1}
}

