-- Function: public.segment_test(integer)

-- DROP FUNCTION public.segment_test(integer);

CREATE OR REPLACE FUNCTION public.segment(arg_traj integer)
  RETURNS void AS
$BODY$

                                                                            
DECLARE
                                                                                
      arg_raw_point_id integer;
      first_point integer;
      angle_filter integer; 
      counter bool;    
      arg_start geometry;
      arg_end geometry;
      arg_segment geometry;
      arg_angle double precision;
      pre_angle double precision;
      arg_time character varying(254);
      arg_segment_id integer;
      curr_rec record;
      arg_correct bool;
      assign_rec record;
      epochtime double precision;
      right_candidate integer; 
      wrong_candidate integer; 
      
       
        
        
BEGIN
      --initializations
	angle_filter:=120; 

	delete from segment where traj_id=arg_traj; 
       
        pre_angle :=-1;
        arg_correct := 't';
        first_point := 0;
        right_candidate :=1;
        wrong_candidate :=-1;
  FOR curr_rec IN Select distinct on(id)id FROM candidate where  traj_id=arg_traj order by id asc
  LOOP
       
	
	
 IF first_point =0 THEN
        
        first_point :=1; 
        arg_raw_point_id := curr_rec.id;

			
       
        
        ELSE
        
		counter := 'f';
		right_candidate :=1;
                wrong_candidate :=-1;
		FOR assign_rec IN Select * From candidate where id=curr_rec.id and traj_id=arg_traj order by candidate_id asc
		LOOP
			--raise notice 'id % cand %',assign_rec.id,assign_rec.candidate_id;
			IF abs(assign_rec.angle_diff-assign_rec.road_angle)< angle_filter or (360-abs(assign_rec.angle_diff-assign_rec.road_angle))<angle_filter then			

			
			counter := 't';
                        --raise notice 'id % cand_a %',assign_rec.angle_diff,assign_rec.road_angle;

			INSERT INTO segment VALUES ( assign_rec.id,assign_rec.traj_id,assign_rec.segment_id,assign_rec.segment,assign_rec.time_in_timestamp,assign_rec.epoch_time,right_candidate,arg_correct);
			--Update candidate set candidate_id=right_candidate where id=curr_rec.id and traj_id=arg_traj and  candidate_id =assign_rec.candidate_id ;

			
		        --Update action is slow so we use the delete and insert.
			
			right_candidate := right_candidate+1;

                        
			

			ELSE

			
		        
			--Update candidate set candidate_id=  wrong_candidate where id=curr_rec.id and traj_id=arg_traj and  candidate_id =assign_rec.candidate_id ;
				

			END IF;
			
		END LOOP;

		IF not counter THEN
		--raise notice 'id % cand ',arg_raw_point_id ;
		--delete from segment  where id=arg_raw_point_id and traj_id=arg_traj;
		--INSERT INTO segment select curr_rec.id,curr_rec.traj_id,curr_rec.segment_id,curr_rec.segment,curr_rec.time_in_timestamp,curr_rec.epoch_time);

		        --raise notice 'delete_id: %',curr_rec.id;
			--delete from segment 
			--Where id=curr_rec.id and traj_id=arg_traj;

		END IF;

		IF first_point =1 THEN

			counter := 'f';
			right_candidate :=1;
                        wrong_candidate :=-1;

			FOR assign_rec IN Select * From candidate where id=arg_raw_point_id and traj_id=arg_traj order by candidate_id asc
			LOOP
				IF abs(assign_rec.angle_diff-assign_rec.road_angle)< angle_filter or (360-abs(assign_rec.angle_diff-assign_rec.road_angle))<angle_filter  then			

				
                                --raise notice 'id % cand %',assign_rec.id,right_candidate;
				INSERT INTO segment VALUES ( assign_rec.id,assign_rec.traj_id,assign_rec.segment_id,assign_rec.segment,assign_rec.time_in_timestamp,assign_rec.epoch_time,right_candidate,arg_correct);
			 
				--Update candidate set candidate_id=right_candidate where id=curr_rec.id and traj_id=arg_traj and  candidate_id =assign_rec.candidate_id ;

				counter := 't';
				right_candidate := right_candidate+1;
				
				 --Update action is slow so we use the delete and insert.
				 
				
				

				ELSE

				--Update candidate set candidate_id=  wrong_candidate where id=curr_rec.id and traj_id=arg_traj and  candidate_id =assign_rec.candidate_id ;
				--delete from candidate  where id=curr_rec.id and traj_id=arg_traj and candidate_id =assign_rec.candidate_id ;

				END IF;
			END LOOP;


			IF not counter THEN
			--raise notice 'id % cand ',arg_raw_point_id  ;
			--delete from segment  where id=arg_raw_point_id and traj_id=arg_traj;
			--delete from segment 
			--Where id=arg_raw_point_id and traj_id=arg_traj;

			END IF;

		first_point :=2;
		END IF;

END IF;
        
             
END LOOP;
perform connect_cost(arg_traj,6);
        END;
        

$BODY$
  LANGUAGE plpgsql;
--select segment(10);
