-- Function: public.candidate(integer)

-- DROP FUNCTION public.candidate(integer);

CREATE OR REPLACE FUNCTION public.candidate(arg_traj integer)
  RETURNS integer AS
$BODY$

                                                                            
DECLARE
                                                                                
      arg_raw_point_id integer;
      arg_candidate integer;
      arg_raw_point geometry;      
      arg_distance float4;
      first_ptr bool;
      arg_id bigint;
      arg_angle double precision;
      dist double precision;
      radius_bound double precision;
      pre_angle double precision;
      arg_dist_diff double precision;
      arg_raw_angle double precision;
      error_radius double precision;
      pre_radius_time double precision;
      arg_time character varying(254);
      arg_segment_id integer;
      curr_rec record;
      prev_rec record;
      segment geometry;
      candidate_rec record;
      is_junction bool;

       StartTime timestamptz;
       EndTime timestamptz;
       Delta interval;
    
      
       
        
        
BEGIN
      --initializations
        StartTime := clock_timestamp();
        error_radius :=20;
        arg_raw_point_id :=1;
        first_ptr = 't';
	pre_angle = -1;
	delete from candidate where traj_id=arg_traj; 
        FOR curr_rec IN Select * FROM data where traj_id=arg_traj order by epoch_time asc
       
  LOOP
	Update data set id= arg_raw_point_id where traj_id= arg_traj and epoch_time= curr_rec.epoch_time;
	is_junction = 'f';
	--select ST_Dwithin(curr_rec.the_geom,junction.the_geom, 0.008) from junction into is_junction;

	IF is_junction THEN
        radius_bound := 0.0015; 
        ELSE
        radius_bound := 0.0015; 
	END IF;
	
        arg_raw_point_id :=  arg_raw_point_id +1;

        IF  first_ptr THEN
	--raise notice 'bool: %', first_ptr;
	arg_id=curr_rec.id;
	arg_raw_point := curr_rec.the_geom;
	prev_rec := curr_rec;
	pre_radius_time:=curr_rec.epoch_time;
	first_ptr := 'f';
	arg_raw_angle := -1;
	arg_candidate :=1;
	
     
	FOR candidate_rec IN SELECT id,the_geom
	FROM network_tp 
	where ST_Dwithin(curr_rec.the_geom,network_tp.the_geom, radius_bound)
	--0.00150* 111100=155m
	ORDER BY ST_distance(curr_rec.the_geom,network_tp.the_geom) 
	

    
		LOOP
        
       
		
		SELECT angle FROM  network_tp 
		where id=candidate_rec.id INTO arg_angle;

		segment:=candidate_rec.the_geom;

		arg_dist_diff := ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(candidate_rec.the_geom),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(curr_rec.the_geom),4326),26986));
	
		INSERT INTO candidate VALUES ( curr_rec.id ,curr_rec.traj_id,curr_rec.the_geom,arg_candidate,candidate_rec.id,candidate_rec.the_geom,arg_angle,arg_raw_angle,arg_dist_diff,curr_rec.time,curr_rec.epoch_time,pre_radius_time,'f');
		arg_candidate = arg_candidate+1;
        
 
		END LOOP;
	ELSE
		arg_raw_angle:=DEGREES(ST_Azimuth(arg_raw_point,curr_rec.the_geom));

		dist:=ST_Distance(arg_raw_point,curr_rec.the_geom);

			IF pre_angle =-1 THEN

			pre_angle := arg_raw_angle; 

			ELSE
			--已有暫存角度,NULL時拿之前暫存的角度更新

				IF arg_angle IS NULL THEN
				arg_raw_angle := pre_angle;
				END IF;
			END IF;	
	
		IF dist> 0 THEN
                        --raise notice 'id: %, arg_id %', curr_rec.id,arg_id;
			--IF (dist*360000)/(curr_rec.epoch_time-prev_rec.epoch_time)>30 THEN
			

				arg_candidate :=1;
     
				FOR candidate_rec IN SELECT id,the_geom
				FROM network_tp 
				where ST_Dwithin(curr_rec.the_geom,network_tp.the_geom, radius_bound) 
				ORDER BY ST_distance(curr_rec.the_geom,network_tp.the_geom) 
	

    
				LOOP
                
       
		
				SELECT angle FROM  network_tp 
				where id=candidate_rec.id INTO arg_angle;

				segment:=candidate_rec.the_geom;

				arg_dist_diff := ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(candidate_rec.the_geom),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(curr_rec.the_geom),4326),26986));
	
				INSERT INTO candidate VALUES ( curr_rec.id ,curr_rec.traj_id,curr_rec.the_geom,arg_candidate,candidate_rec.id,candidate_rec.the_geom,arg_angle,arg_raw_angle,arg_dist_diff,curr_rec.time,curr_rec.epoch_time,pre_radius_time,'f');
				arg_candidate = arg_candidate+1;
        
 
				END LOOP;

				
				

			
                --change baseline point if without the error radius
			arg_raw_point =curr_rec.the_geom;
			arg_id=curr_rec.id;
			prev_rec := curr_rec;
		        
		ELSE 

	         --store the center point's time if within the error radius 
	        --raise notice 'id: %, red_light %, time %', curr_rec.id,arg_id,curr_rec.epoch_time;
	 	pre_radius_time:=curr_rec.epoch_time;
		Update candidate set red_light='t',center_time=curr_rec.epoch_time where id=arg_id and traj_id=arg_traj;


		END IF;
        END IF;
      
 END LOOP;
            
        perform segment(arg_traj);
        --raise notice 'finish_trajectory: %', arg_traj;
         EndTime := clock_timestamp();
        --raise notice '%',EndTime;
        Delta := 1000 * ( extract(epoch from EndTime) - extract(epoch from StartTime) );
        --raise notice '%',floor(extract(epoch from Delta));
        Update exp set exp3_execute_ms=floor(extract(epoch from Delta)) where traj_id=arg_traj;
       return arg_traj;
     END;
        


$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.candidate(integer)
  OWNER TO postgres;
--selselect candidate(7);
