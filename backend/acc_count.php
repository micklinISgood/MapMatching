<?php
$data=array();
// Connecting, selecting database
$dbconn = pg_connect("host=plash.iis.sinica.edu.tw dbname=e_bus user=postgres password=root")
    or die('Could not connect: ' . pg_last_error());


// Performing SQL query

//$query = array(7,10,12,14,24,25,29,34,48,51,69,73,77,111,113,124,135,140,148,160,171,197,245,263,289,336,339,341,437,441);
$query = $_POST["trajs"];
$result = pg_query($dbconn, 'delete from acc_res')or die('Query failed: ' . pg_last_error());

for ($i=0;$i <30; $i++){
$result = pg_query_params($dbconn, 'select count(distinct(pid))  from truth where traj_id =$1', array($query[$i]))or die('Query failed: ' . pg_last_error());
$error = pg_fetch_array($result, null, PGSQL_ASSOC);
$result = pg_query_params($dbconn, 'select count(*)  from speed where traj_id =$1', array($query[$i]))or die('Query failed: ' . pg_last_error());
$sample = pg_fetch_array($result, null, PGSQL_ASSOC);
// Printing results in HTML

$acc = 1-$error[count]/$sample[count];
$result = pg_query_params($dbconn, 'insert into acc_res(traj_id,acc) values($1,$2)', array($query[$i],$acc))or die('Query failed: ' . pg_last_error());

//echo "Q: ".$sample[count]."<br/>";	
//echo "error: ".$error[count]."<br/>";
//echo "a: ".$acc."<br/>";
}
$result = pg_query($dbconn, 'select * from acc_res order by acc')or die('Query failed: ' . pg_last_error());
while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
  
		array_push($data,$line);
	
	}
$result = pg_query($dbconn, 'select create_ground_truth()')or die('Query failed: ' . pg_last_error());
// Free resultset
pg_free_result($result);

// Closing connection
pg_close($dbconn);
echo json_encode($data);
?>

