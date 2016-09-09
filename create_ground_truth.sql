CREATE OR REPLACE FUNCTION public.create_ground_truth ()
  RETURNS void AS
$BODY$

                                                                            
DECLARE
		
		curr_rec record;
		distinc_rec record;
		arg_lat double precision;
		arg_lng double precision;
        
BEGIN
      
    
	delete from ground_truth;
	For curr_rec in select traj_id as id from acc_res group by traj_id order by traj_id 
    	
	LOOP
        insert into ground_truth select * from speed where traj_id=curr_rec.id;
	For distinc_rec in select distinct(pid) from truth where traj_id= curr_rec.id
		LOOP
			select lat,lng into arg_lat,arg_lng from truth where pid=distinc_rec.pid and traj_id=curr_rec.id order by epoch desc limit 1;
			Update ground_truth set close_point=ST_MakePoint(arg_lng,arg_lat),lat=arg_lat,lng=arg_lng where traj_id= curr_rec.id and pid=distinc_rec.pid;
			

		END LOOP;


		
		
	END LOOP;


	

		
		
        END;
        
$BODY$
  LANGUAGE plpgsql;

select create_ground_truth();
