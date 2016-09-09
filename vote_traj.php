<?php
$token=$_POST["token"];
//$token=7;

// Connecting, selecting database
$dbconn = pg_connect("host=plash.iis.sinica.edu.tw dbname=e_bus user=postgres password=root")
    or die('Could not connect: ' . pg_last_error());
$total = array();

// Performing SQL query
$result = pg_query_params($dbconn, 'select count(*) FROM ground_truth  WHERE traj_id = $1', array($token))or die('Query failed: ' . pg_last_error());
$line = pg_fetch_array($result, null, PGSQL_ASSOC);

if($line[count]>0){
	
	$result = pg_query_params($dbconn, 'SELECT id,lat,lng,speed,time_in_timestamp FROM ground_truth   WHERE traj_id = $1 order by epoch_time asc', array($token))or die('Query failed: ' . pg_last_error());
	$matched = array();
	// Printing results in HTML


		while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
  
			array_push($matched,$line);
	
		}
	
}
else{
	$result = pg_query_params($dbconn, 'SELECT id,lat,lng,speed,time_in_timestamp FROM speed  WHERE traj_id = $1 order by epoch_time asc', array($token))or die('Query failed: ' . pg_last_error());
	$matched = array();
	// Printing results in HTML


		while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
  
			array_push($matched,$line);
	
		}
}
	
$result = pg_query_params($dbconn, 'SELECT id,lng,lat,time,epoch_time FROM data where traj_id=$1 order by epoch_time asc ', array($token))or die('Query failed: ' . pg_last_error());

$raw = array();
// Printing results in HTML

	while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
  
		array_push($raw,$line);
	}
$total['traj_id']=$token;
array_push($total,$matched);
array_push($total,$raw);

// Free resultset
pg_free_result($result);

// Closing connection
pg_close($dbconn);

echo json_encode($total);
?>

