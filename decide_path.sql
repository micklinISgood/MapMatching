-- Function: public.decide_path_test(integer)

-- DROP FUNCTION public.decide_path_test(integer);

CREATE OR REPLACE FUNCTION public.decide_path(arg_traj integer)
  RETURNS void AS
$BODY$

                                                                            
DECLARE
                                                                                
     curr_rec record;
     prev_rec record;
     s_cost_rec record;
     t_cost_rec record;
     keep_rec record;
 
     first bool;
     keep_cand integer;
     keep_segment_id integer;
     final_segment_id integer;
     final_cand integer;

     arg_segment geometry;
     arg_time timestamp;
     arg_epoch double precision;
   
   
     tmp_cost double precision;
     
        
        
BEGIN
      --initializations
      
	 delete from decide_path where traj_id=arg_traj;
	 
	 first := true;
	
 
  FOR curr_rec IN select distinct on (s_id)* from connect_cost where traj_id=arg_traj  order by s_id asc
  LOOP
    
	IF first THEN
		--from segment 1, candidate 1
                
              
                INSERT INTO decide_path select curr_rec.traj_id,curr_rec.s_id,connect_cost.s_cand,connect_cost.t_id,t_cand,cost,s_segment_id from connect_cost where traj_id = arg_traj and s_id=curr_rec.s_id; 
                prev_rec := curr_rec;
		first := false;

		For keep_rec in select distinct on(t_cand)* from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id  order by t_cand asc 
                  LOOP
		  select s_cand,cost from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id and t_cand=keep_rec.t_cand order by cost asc limit 1 into keep_cand,tmp_cost;
		  raise notice'keep % t_id % cost % ',keep_rec.s_id,keep_cand,tmp_cost ;

		  IF keep_cand >0 THEN
		  delete from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id and t_cand=keep_rec.t_cand  and s_cand != keep_cand;
		  ELSE
		  delete from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id and t_cand=keep_rec.t_cand  and cost != tmp_cost;
		  END IF;
			
		  END LOOP;
		
		
		
		
	ELSE
               
		
		
		        
		
			-- select the prev three candidates
			
			For s_cost_rec IN Select t_cand,cost from decide_path where traj_id = arg_traj  and s_id=prev_rec.s_id order by t_cand asc 
			LOOP

			--add current cost from prev candidate to current candidate
			For t_cost_rec in Select t_cand,cost,s_segment_id from connect_cost where traj_id = arg_traj  and  s_id=curr_rec.s_id and s_cand=s_cost_rec.t_cand and t_id= curr_rec.t_id order by t_cand asc
			LOOP
		        --select cost from decide_path where s_id=curr_rec.s_id into ref_cost;

		        raise notice'sid % c % tid % c % t %',curr_rec.s_id,s_cost_rec.t_cand,curr_rec.t_id,t_cost_rec.t_cand,(s_cost_rec.cost+t_cost_rec.cost) ;

			-- n*n times, 3*3 
			

			

			INSERT INTO decide_path values (arg_traj,curr_rec.s_id,s_cost_rec.t_cand,curr_rec.t_id,t_cost_rec.t_cand,s_cost_rec.cost+t_cost_rec.cost,t_cost_rec.s_segment_id);
			
			
			
			--raise notice's % t %',s_cost_rec.cost,t_cost_rec.cost ;

			
                        END LOOP;
                        

			END LOOP;
                  
                  For keep_rec in select distinct on(t_cand)* from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id  order by t_cand asc 
                  LOOP
		  select s_cand,cost from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id and t_cand=keep_rec.t_cand order by cost asc limit 1 into keep_cand,tmp_cost;
		  raise notice'keep % t_id % cost % ',keep_rec.s_id,keep_cand,tmp_cost ;

		  IF keep_cand >0 THEN
		  delete from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id and t_cand=keep_rec.t_cand  and s_cand != keep_cand;
		  ELSE
		  delete from decide_path where traj_id = arg_traj and t_id=curr_rec.t_id and t_cand=keep_rec.t_cand  and cost != tmp_cost;
		  END IF;
			
		  END LOOP;
		 
		 
		
	


                  
                prev_rec := curr_rec;



        END IF;







  END LOOP;



 first :=true;
 For curr_rec in select distinct on(s_id)* from decide_path where traj_id = arg_traj order by s_id desc
 LOOP

	IF first THEN
		select s_cand,t_cand,cost,s_segment_id from decide_path where  traj_id = arg_traj and  s_id=curr_rec.s_id and s_cand=curr_rec.s_cand order by cost limit 1 into keep_cand,final_cand,tmp_cost,keep_segment_id;
		select segment_id into final_segment_id from segment where id=curr_rec.t_id and traj_id=arg_traj and candidate_id=final_cand;
		insert into decide_path values (curr_rec.traj_id,curr_rec.t_id,final_cand,0,0,0,final_segment_id);
		delete from decide_path where  traj_id = arg_traj and  s_id=curr_rec.s_id ;
		INSERT into decide_path values (curr_rec.traj_id,curr_rec.s_id,keep_cand,curr_rec.t_id,final_cand,tmp_cost,keep_segment_id);
		first := false;
		prev_rec := curr_rec;
		prev_rec.s_cand := keep_cand;

	ELSE
		
		select s_cand,s_segment_id from decide_path where traj_id = arg_traj and t_id=prev_rec.s_id and t_cand=prev_rec.s_cand order by cost limit 1 into keep_cand,keep_segment_id;
		delete from decide_path where traj_id = arg_traj and  s_id=curr_rec.s_id ;
		INSERT into decide_path values (curr_rec.traj_id,curr_rec.s_id,keep_cand,curr_rec.t_id,prev_rec.s_cand,tmp_cost,keep_segment_id);
                prev_rec := curr_rec;
                prev_rec.s_cand := keep_cand;


	END IF;

 END LOOP;

delete from segment where traj_id=arg_traj;
For curr_rec in select * from decide_path where traj_id=arg_traj order by s_id
LOOP
	SELECT segment,time_in_timestamp,epoch_time into arg_segment, arg_time, arg_epoch from candidate where id=curr_rec.s_id and traj_id=curr_rec.traj_id and segment_id=curr_rec.s_segment_id;
	INSERT INTO segment VALUES (curr_rec.s_id,curr_rec.traj_id,curr_rec.s_segment_id,arg_segment, arg_time, arg_epoch,curr_rec.s_cand,'t');

END LOOP;

 --delete from segment using decide_path where segment.traj_id=arg_traj and decide_path.traj_id=arg_traj and id <> decide_path.s_id; 
 
 --delete from segment using decide_path where segment.traj_id=arg_traj and decide_path.traj_id=arg_traj and id=decide_path.s_id and candidate_id != decide_path.s_cand; 
 --insert into segment select candidate.id,candidate.traj_id,candidate.segment_id,candidate.segment,candidate.time_in_timestamp,candidate.epoch_time,candidate.candidate_id,'t' from candidate,decide_path where candidate.traj_id=arg_traj  and decide_path.traj_id=arg_traj and candidate.id=decide_path.s_id and candidate.candidate_id=decide_path.s_cand ;
 perform connect(arg_traj);
 

/*
 delete from segment where traj_id=arg_traj;
 insert into segment select candidate.id,candidate.traj_id,candidate.segment_id,candidate.segment,candidate.time_in_timestamp,candidate.epoch_time,candidate.candidate_id,'t' from candidate,decide_path where candidate.traj_id=arg_traj  and decide_path.traj_id=arg_traj and 
 candidate.id=decide_path.s_id and candidate.candidate_id=decide_path.s_cand ;
 perform connect(arg_traj);
 */

        END;
        

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.decide_path(integer)
  OWNER TO postgres;
