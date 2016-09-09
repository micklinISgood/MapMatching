-- Function: public.connect_cost(integer, integer)

-- DROP FUNCTION public.connect_cost(integer, integer);

CREATE OR REPLACE FUNCTION public.connect_cost(arg_traj integer, arg_window integer)
  RETURNS void AS
$BODY$

                                                                            
DECLARE
		
		curr_rec record;
		segment_1_rec record;
		segment_2_rec record;
		
		
		rp_1 geometry;
		
		adjust_time double precision;
		closest_point_1 geometry;
		closest_point_2 geometry;
		segment2 geometry;
		arg_rel1 integer;
		arg_rel2 integer;
		firstpoint integer;
		prev_id integer;
		interpoint geometry;
		arg_s integer;
		arg_t integer;
		arg_s1 integer;
		arg_t1 integer;
		arg_s2 integer;
		arg_t2 integer;
		dij_tmp integer;
		acceleration_limit integer;
		arg_s1_geom geometry;
		arg_s2_geom geometry;
		arg_t1_geom geometry;
		arg_t2_geom geometry;
		min_dist double precision;
		dist double precision;
		dist1 double precision;
		dist2 double precision;
		arg_speed double precision;
		
		gap double precision;
		ad_time timestamp;
		prev_rec record;
		dij_rec record;
		dij_segment geometry;
		dij_point geometry;
		isolate bool;
		wrong_point bool;
 	      	iso_int integer;
 	      	time_gap integer;
 	      	counter integer;
 	      	s_time bigint;
 	      	e_time bigint;
 	      	traj_points integer;
 	      	default_gap double precision;
 	      	error_radius integer;
 	      	arg_day_of_week double precision;
		arg_slot double precision;
        
BEGIN
      --initializations
	
       
		firstpoint:=0;
		
		
		
		
    
	delete from connect_cost where traj_id=arg_traj;
	
        FOR curr_rec IN Select id FROM candidate where traj_id=arg_traj and candidate_id=1 order by epoch_time asc
		
		LOOP
		        wrong_point := 'f';  dist :=0.0; dist1 :=0.0; dist2 :=0.0;gap =0.0;counter:=1; 
			IF firstpoint =0 THEN

				prev_id := curr_rec.id;
				firstpoint :=1;
				
			ELSE 

			        For segment_1_rec IN Select segment_id,segment,candidate_id,epoch_time FROM segment where  id=prev_id and traj_id=arg_traj and candidate_id<=arg_window and candidate_id>0 order by candidate_id asc
                                LOOP
                                For segment_2_rec IN Select segment_id,segment,candidate_id,epoch_time  FROM segment where  id=curr_rec.id and traj_id=arg_traj and candidate_id<=arg_window and candidate_id>0 order by candidate_id asc
                                LOOP
				 
		               
				
			      
				IF segment_1_rec.segment_id  = segment_2_rec.segment_id THEN

				Select source INTO arg_s1 
				From network_tp
				Where id= segment_1_rec.segment_id;

				INSERT INTO connect_cost VALUES (arg_traj,prev_id,segment_1_rec.candidate_id,segment_1_rec.segment,curr_rec.id,segment_2_rec.candidate_id,0,segment_1_rec.segment_id);
                               
				

					
				ELSIF segment_1_rec.segment_id != segment_2_rec.segment_id AND ST_Intersects(segment_1_rec.segment,segment_2_rec.segment) THEN

				Select source INTO arg_s1 
				From network_tp
				Where id= segment_1_rec.segment_id;
				Select source INTO arg_t1 
				From network_tp
				Where id= segment_2_rec.segment_id ;
				Select target INTO arg_s2 
				From network_tp
				Where id= segment_1_rec.segment_id;
				Select target INTO arg_t2 
				From network_tp
				Where id= segment_2_rec.segment_id ;
				
				IF arg_s1 =arg_t1 or arg_s1 =arg_t2   THEN

				INSERT INTO connect_cost VALUES (arg_traj,prev_id,segment_1_rec.candidate_id,segment_1_rec.segment,curr_rec.id,segment_2_rec.candidate_id,0,segment_1_rec.segment_id);

				ELSE

                                INSERT INTO connect_cost VALUES (arg_traj,prev_id,segment_1_rec.candidate_id,segment_1_rec.segment,curr_rec.id,segment_2_rec.candidate_id,0,segment_1_rec.segment_id);

				END IF;

				
                               

				
				ELSIF segment_1_rec.segment_id  != segment_2_rec.segment_id  AND NOT ST_Intersects(segment_1_rec.segment,segment_2_rec.segment)THEN
				dist :=0;
				--raise notice 'log_sp:%',1; 
                                Select source INTO arg_s1 
				From network_tp
				Where id= segment_1_rec.segment_id;
				
				Select source INTO arg_t1 
				From network_tp
				Where id= segment_2_rec.segment_id ;
				Select target INTO arg_s2 
				From network_tp
				Where id= segment_1_rec.segment_id;
				Select target INTO arg_t2 
				From network_tp
				Where id= segment_2_rec.segment_id ;
				Select the_geom INTO arg_s1_geom 
				From network_tp_vertices_pgr
				Where id= arg_s1;
				Select the_geom INTO arg_s2_geom 
				From network_tp_vertices_pgr
				Where id= arg_s2;
				Select the_geom INTO arg_t1_geom 
				From network_tp_vertices_pgr
				Where id= arg_t1;
				Select the_geom INTO arg_t2_geom 
				From network_tp_vertices_pgr
				Where id= arg_t2;
				IF (ST_Distance(arg_s1_geom,arg_t1_geom) <1000 ) THEN
				arg_s := arg_s1;
				arg_t := arg_t1;
				min_dist := ST_Distance(arg_s1_geom,arg_t1_geom);
				END IF;
				IF (ST_Distance(arg_s1_geom,arg_t2_geom) <min_dist ) THEN
				arg_s := arg_s1;
				arg_t := arg_t2;
				min_dist := ST_Distance(arg_s1_geom,arg_t2_geom);
				END IF;
				IF (ST_Distance(arg_s2_geom,arg_t1_geom) <min_dist) THEN
				arg_s := arg_s2;
				arg_t := arg_t1;
				min_dist := ST_Distance(arg_s2_geom,arg_t1_geom);
				END IF;
				IF (ST_Distance(arg_s2_geom,arg_t2_geom) <min_dist) THEN
				arg_s := arg_s2;
				arg_t := arg_t2;
				END IF;

			Select count(*) from dij_path where s_id =arg_s and t_id=arg_t and seq=0 into dij_tmp;

			raise notice 'id % s_c % s % t %',prev_id,segment_1_rec.candidate_id,arg_s,arg_t; 
			
			--store dijkstra path if the query path doesn't exist
			IF dij_tmp !=1 THEN
				delete from dij_path where s_id =arg_s and t_id=arg_t; 
				For dij_rec IN SELECT seq,id1,id2,cost FROM pgr_dijkstra('SELECT id,source::integer,target::integer,cost::double precision FROM network_tp',arg_s,arg_t,true,false)
					LOOP

					INSERT INTO dij_path VALUES (arg_s,arg_t,dij_rec.seq,dij_rec.id1,dij_rec.id2,dij_rec.cost);
					
						
                                                  IF dij_rec.id2 != -1 THEN
			
						  dist := dist+dij_rec.cost;
						  
						  END IF;
						  
        
					END LOOP;

				IF dist != 0 and ((dist*3.6)/(segment_2_rec.epoch_time-segment_1_rec.epoch_time))<180  THEN	 

			           INSERT INTO connect_cost VALUES (arg_traj,prev_id,segment_1_rec.candidate_id,segment_1_rec.segment,curr_rec.id,segment_2_rec.candidate_id,dist,segment_1_rec.segment_id);   
				 
                                 
				 ELSE
				 --dijkstra fail
                               
                                 END IF;


                               ELSE

                               For dij_rec IN SELECT seq,id1,id2,cost FROM dij_path where s_id =arg_s and t_id=arg_t order by seq asc
					LOOP
					
				
						
                                                  IF dij_rec.id2 != -1 THEN
					
						  dist := dist+dij_rec.cost;
						  
						  END IF;
						  
							
        
					END LOOP;

				IF dist != 0 and ((dist*3.6)/(segment_2_rec.epoch_time-segment_1_rec.epoch_time))<180  THEN	 
				        
                                  INSERT INTO connect_cost VALUES (arg_traj,prev_id,segment_1_rec.candidate_id,segment_1_rec.segment,curr_rec.id,segment_2_rec.candidate_id,dist,segment_1_rec.segment_id);   
				 


			         ELSE
                                 --dijkstra fail
                                
                                 END IF;
                               

			    END IF;  
                                 
                           
                         END IF;

				
			
		
	
			END LOOP;
			END LOOP;
              
		prev_id := curr_rec.id;
	
		
	        END IF;
		
		END LOOP;

	

	perform decide_path(arg_traj);

		
		
        END;
        
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.connect_cost(integer, integer)
  OWNER TO postgres;

 -- select connect_cost(7, 6);
