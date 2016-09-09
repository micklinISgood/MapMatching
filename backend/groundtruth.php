<?php
$id= $_POST["id"];
//$token=7;
$time = date("Y-m-d")." ".date("H:i:s");
//echo round(microtime(true)) ;

// Connecting, selecting database
$dbconn = pg_connect("host=plash.iis.sinica.edu.tw dbname=e_bus user=postgres password=root")
    or die('Could not connect: ' . pg_last_error());


// Performing SQL query
$result = pg_query_params($dbconn, 'INSERT INTO truth(traj_id,pid,epoch,uuid,lat,lng) values ($1,$2,$3,$4,$5,$6)', array($_POST["traj_id"],$_POST["pid"],round(microtime(true)),$_POST["id"],$_POST["lat"],$_POST["lng"]))or die('Query failed: ' . pg_last_error());
//$result = pg_query($dbconn, 'select create_ground_truth()')or die('Query failed: ' . pg_last_error());


//echo date("Y-m-d").date("H:i:s");
// Free resultset
pg_free_result($result);

// Closing connection
pg_close($dbconn);

echo json_encode(array(status_code=>200));
?>

