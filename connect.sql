-- Function: public."connect"(integer)

-- DROP FUNCTION public."connect"(integer);

CREATE OR REPLACE FUNCTION public."connect"(arg_traj integer)
  RETURNS void AS
$BODY$

                                                                            
DECLARE
		
		
		
		--related insert data
		rp_1 geometry;
		closest_point_1 geometry;
		closest_point_2 geometry;
		segment2 geometry;
 	      	arg_day_of_week double precision;
		arg_slot double precision;
		arg_speed double precision;
		dij_segment geometry;
		dij_sub_segment geometry;
		dij_point geometry;

		--time calculus related
		gap double precision;
		ad_time timestamp;
		adjust_time double precision;	
 	      	traj_points integer;
 	      	default_gap double precision;

		
		--minimum distance related
		arg_s integer;
		arg_t integer;
		arg_s1 integer;
		arg_t1 integer;
		arg_s2 integer;
		arg_t2 integer;
		
		arg_s1_geom geometry;
		arg_s2_geom geometry;
		arg_t1_geom geometry;
		arg_t2_geom geometry;
		m_point geometry;
		
		
		
		--distance calculus related
		min_dist double precision;
		dist double precision;
		dist1 double precision;
		dist2 double precision;
		total_dist double precision;
		
		
		
		
		--iterators
		curr_rec record;
		prev_rec record;
		dij_rec record;
		
		
		--control parameters
		isolate bool;
		arg_red_light bool;
		delete_signal bool;
		first_dij bool;
		first_wrong bool;
		firstpoint integer;
		arg_pid integer;
		dij_final integer;
		dij_sub integer;
		dij_tmp integer;
		exist integer;
		final_id integer;
		error double precision;
		total double precision;
		rate double precision;
 	  
 	      
 	      
        
BEGIN
      --initializations
	
	delete from speed where traj_id=arg_traj; 
        --delete from junction where traj_id=arg_traj; 
		firstpoint:=0;
		error:=0;
		arg_pid :=1;
	
		
		
     
	select count(*) from data where  traj_id =arg_traj into traj_points;
	
	select id into final_id from segment where traj_id=arg_traj order by id desc limit 1;
        FOR curr_rec IN Select * FROM segment where traj_id=arg_traj order by epoch_time asc
		
		LOOP
		        first_wrong :='f';isolate := 'f'; arg_red_light:='f'; dist :=0.0; dist1 :=0.0; dist2 :=0.0;gap =0.0;
			IF firstpoint =0 THEN

				prev_rec:=curr_rec;

				Select raw_point From candidate Where id= curr_rec.id and traj_id=arg_traj INTO rp_1; 

				closest_point_1 := ST_ClosestPoint(prev_rec.segment,rp_1);

				firstpoint :=curr_rec.id;

				arg_day_of_week=EXTRACT (ISODOW from curr_rec.time_in_timestamp);

				arg_slot= 100*EXTRACT (hour from curr_rec.time_in_timestamp)+EXTRACT (minute from curr_rec.time_in_timestamp);

				

				INSERT INTO speed VALUES (prev_rec.id,arg_traj,closest_point_1,ST_Y(closest_point_1),ST_X(closest_point_1),prev_rec.segment_id,prev_rec.segment,0,prev_rec.time_in_timestamp,prev_rec.epoch_time,'f',arg_day_of_week,arg_slot,arg_pid);
				arg_pid :=arg_pid+1;
				
			ELSE 
				 
		       
				segment2 :=curr_rec.segment;

				Select raw_point From candidate	Where id= curr_rec.id and traj_id=arg_traj INTO rp_1; 
				
				closest_point_2 := ST_ClosestPoint(segment2,rp_1);

				Select red_light from candidate where id =prev_rec.id and traj_id = arg_traj into arg_red_light;
		
				IF arg_red_light THEN 

				
				Select center_time from candidate where id =prev_rec.id and traj_id = arg_traj into prev_rec.epoch_time;
         
				END IF;
				
			        --同segment
				IF prev_rec.segment = segment2 THEN
				
                                dist :=ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(closest_point_1),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(closest_point_2),4326),26986));
				gap := (curr_rec.epoch_time-prev_rec.epoch_time);
                             
                                arg_speed := (dist*3.6)/ gap;
                                arg_day_of_week=EXTRACT (ISODOW from curr_rec.time_in_timestamp);
				arg_slot= 100*EXTRACT (hour from curr_rec.time_in_timestamp)+EXTRACT (minute from curr_rec.time_in_timestamp);
				
			        
				INSERT INTO speed VALUES (curr_rec.id,arg_traj,closest_point_2,ST_Y(closest_point_2),ST_X(closest_point_2),curr_rec.segment_id,segment2,arg_speed,curr_rec.time_in_timestamp,curr_rec.epoch_time,'f',arg_day_of_week,arg_slot,arg_pid);
				arg_pid :=arg_pid+1;
				

				--交一點	
				ELSIF prev_rec.segment_id != curr_rec.segment_id AND ST_Intersects(prev_rec.segment,segment2) THEN
				
                                dist1:=ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(closest_point_1),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(ST_Intersection(prev_rec.segment,segment2)),4326),26986));
                                dist2:=ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(closest_point_2),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(ST_Intersection(prev_rec.segment,segment2)),4326),26986));
                                dist := dist1+dist2;
                               
                                gap := (curr_rec.epoch_time-prev_rec.epoch_time);
                               
                                arg_speed := (dist*3.6)/ (gap);

                                IF dist1 !=0 and dist !=0 and dist2 !=0  THEN
                                adjust_time := prev_rec.epoch_time;
                                adjust_time:= adjust_time+((gap*dist1)/dist);
                                SELECT to_timestamp(adjust_time)-interval '8 hour' into ad_time;
                              
                                 
                                closest_point_1 :=ST_Intersection(prev_rec.segment,segment2);
                                arg_day_of_week=EXTRACT (ISODOW from ad_time);
				arg_slot= 100*EXTRACT (hour from ad_time)+EXTRACT (minute from ad_time);
				INSERT INTO speed VALUES (curr_rec.id,arg_traj,closest_point_1,ST_Y(closest_point_1),ST_X(closest_point_1),curr_rec.segment_id,segment2,arg_speed,ad_time,adjust_time,'t',arg_day_of_week,arg_slot,arg_pid);
				arg_pid :=arg_pid+1;
				

				END IF;
				arg_day_of_week=EXTRACT (ISODOW from curr_rec.time_in_timestamp);
				arg_slot= 100*EXTRACT (hour from curr_rec.time_in_timestamp)+EXTRACT (minute from curr_rec.time_in_timestamp);
				
				INSERT INTO speed VALUES (curr_rec.id,arg_traj,closest_point_2,ST_Y(closest_point_2),ST_X(closest_point_2),curr_rec.segment_id,segment2,arg_speed,curr_rec.time_in_timestamp,curr_rec.epoch_time,'f',arg_day_of_week,arg_slot,arg_pid);
				 arg_pid :=arg_pid+1;                           
				
				
				

				--無交點
				ELSIF prev_rec.segment_id != curr_rec.segment_id AND NOT ST_Intersects(prev_rec.segment,segment2)THEN

				m_point = ST_ClosestPoint(prev_rec.segment,segment2);
				--raise notice 'log_sp:%',1; 

                                Select source INTO arg_s1 From network_tp Where id= prev_rec.segment_id;
                                Select target INTO arg_s2 From network_tp Where id= prev_rec.segment_id;
				Select the_geom INTO arg_s1_geom From network_tp_vertices_pgr Where id= arg_s1;
				--raise notice 'dist 1:%, dist 2 ',ST_Distance(arg_s1_geom,m_point);
				IF ST_Distance(arg_s1_geom,m_point)> 0 THEN
				
					arg_s := arg_s2;

				ELSE
					arg_s := arg_s1;

				END IF;

				m_point = ST_ClosestPoint(segment2,prev_rec.segment);

				Select source INTO arg_t1 From network_tp Where id= curr_rec.segment_id;
                                Select target INTO arg_t2 From network_tp Where id= curr_rec.segment_id;
				Select the_geom INTO arg_t1_geom From network_tp_vertices_pgr Where id= arg_t1;
				--raise notice 'dist 1:%, dist 2  ',ST_Distance(arg_t1_geom,m_point);
				IF ST_Distance(arg_t1_geom,m_point)> 0 THEN
				
					arg_t := arg_t2;

				ELSE
					arg_t := arg_t1;

				END IF;
				--raise notice 'source1:%', prev_rec.segment_id; 
				--raise notice 'id1:%, node %, id2 %, node %', prev_rec.segment_id,arg_s,curr_rec.segment_id,arg_t; 
				

			Select count(*) from dij_path where s_id =arg_s and t_id=arg_t and seq=0 into dij_tmp;

			--store dijkstra path if the query path doesn't exist
			IF dij_tmp != 1 THEN

				delete from dij_path where s_id =arg_s and t_id=arg_t;	
				first_dij := 't';
				For dij_rec IN SELECT seq,id1,id2,cost FROM pgr_dijkstra('SELECT id,source::integer,target::integer,cost::double precision FROM network_tp',arg_s,arg_t,true,false)
					LOOP
								
					INSERT INTO dij_path VALUES (arg_s,arg_t,dij_rec.seq,dij_rec.id1,dij_rec.id2,dij_rec.cost);
					
					IF dij_rec.id2 != prev_rec.segment_id THEN
						IF dij_rec.id2 != curr_rec.segment_id  THEN

						Select the_geom INTO dij_segment  From network_tp  Where id= dij_rec.id2;
						
				                Select the_geom INTO dij_point     From network_tp_vertices_pgr  Where id= dij_rec.id1;
				                
						 IF ST_Intersects(prev_rec.segment,dij_segment)THEN
							dist1:=ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(closest_point_1),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(ST_Intersection(prev_rec.segment,dij_segment)),4326),26986));
                                                  END IF;
                                                 
					         
                                                 

						    IF first_dij THEN
								
								dij_sub := dij_rec.id2;
								dij_sub_segment := dij_segment;
								first_dij := 'f';

									IF dist1 >0 THEN
                        
									INSERT INTO speed VALUES (curr_rec.id,arg_traj,dij_point,ST_Y(dij_point),ST_X(dij_point),dij_rec.id2,dij_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,arg_pid);
									arg_pid :=arg_pid+1;
				
									

									END IF;

								ELSE
								
								 
								 --raise notice 'id %, s %, t %, s_id %, t_id %, dist2 %', arg_pid, arg_s,arg_t, dij_sub,curr_rec.segment_id, dist2;
								IF dij_rec.id2 != -1 THEN
								INSERT INTO speed VALUES (curr_rec.id,arg_traj,dij_point,ST_Y(dij_point),ST_X(dij_point),dij_sub,dij_sub_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,arg_pid);
								arg_pid :=arg_pid+1;

								ELSE
								dist2:=ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(closest_point_2),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(dij_point),4326),26986));
								
									IF dist2 >0 THEN
									INSERT INTO speed VALUES (curr_rec.id,arg_traj,dij_point,ST_Y(dij_point),ST_X(dij_point),dij_sub,dij_sub_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,arg_pid);
									arg_pid :=arg_pid+1;
	
									ELSE

									INSERT INTO speed VALUES (curr_rec.id,arg_traj,null,null,null,dij_sub,dij_sub_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,null);
									END IF;

								END IF;
								
								dij_sub := dij_rec.id2;
								dij_sub_segment := dij_segment;


								END IF;

						
						  
						  
						
						  dist := dist+dij_rec.cost;
						  
							END IF;
							END IF;
        
					END LOOP;

				IF dist != 0 THEN	 
				        dist= dist+dist1+dist2;
				        
				        gap := (curr_rec.epoch_time-prev_rec.epoch_time);
				       
                                        arg_speed := (dist*3.6)/ (gap);
                                 arg_day_of_week=EXTRACT (ISODOW from curr_rec.time_in_timestamp);
				 arg_slot= 100*EXTRACT (hour from curr_rec.time_in_timestamp)+EXTRACT (minute from curr_rec.time_in_timestamp);
				 adjust_time := prev_rec.epoch_time;
				 INSERT INTO speed VALUES (curr_rec.id,arg_traj,closest_point_2,ST_Y(closest_point_2),ST_X(closest_point_2),curr_rec.segment_id,segment2,arg_speed,curr_rec.time_in_timestamp,curr_rec.epoch_time,'f',arg_day_of_week,arg_slot,arg_pid);
				 arg_pid :=arg_pid+1;
                                 

				 For dij_rec IN SELECT * from speed  where id=curr_rec.id and traj_id=arg_traj and interpolate order by pid asc
                                 LOOP

				 IF dij_rec.speed = 0  THEN


					adjust_time = adjust_time+(gap*dist1)/dist;
					SELECT to_timestamp(adjust_time)-interval '8 hour' into ad_time;
					arg_day_of_week=EXTRACT (ISODOW from ad_time);
					arg_slot= 100*EXTRACT (hour from ad_time)+EXTRACT (minute from ad_time);

					
                                 
					Update speed
					Set time_in_timestamp =ad_time, day_of_week=arg_day_of_week, time_slot= arg_slot,epoch_time = adjust_time
					Where pid=dij_rec.pid and id=curr_rec.id and traj_id=arg_traj;

					

                                 ELSE
                                        
					Select cost into dist1 from network_tp where id= dij_rec.segment_id;

					adjust_time = adjust_time+(gap*dist1)/dist;

					SELECT to_timestamp(adjust_time)-interval '8 hour' into ad_time;
					arg_day_of_week=EXTRACT (ISODOW from ad_time);
					arg_slot= 100*EXTRACT (hour from ad_time)+EXTRACT (minute from ad_time);
	
				
				 
					Update speed
					Set time_in_timestamp =ad_time, day_of_week=arg_day_of_week, time_slot= arg_slot,epoch_time = adjust_time
					Where pid=dij_rec.pid and id=curr_rec.id and traj_id=arg_traj;

	

                               

                                 END IF;
                               
				
                                 END LOOP;

				 --Update speed Set speed=arg_speed Where id=curr_rec.id and traj_id=arg_traj and interpolate;
                                 
				 ELSE
				 --dijkstra fail
                                 END IF;


                               ELSE

                               first_dij :='t';
                               raise notice 'id %, s %, t %', arg_pid, arg_s,arg_t;
                               For dij_rec IN SELECT seq,id1,id2,cost FROM dij_path where s_id =arg_s and t_id=arg_t order by seq asc
					LOOP
					
					IF dij_rec.id2 != prev_rec.segment_id THEN
						IF dij_rec.id2 != curr_rec.segment_id  THEN
						Select the_geom INTO dij_segment 
				                From network_tp
				                Where id= dij_rec.id2;
				                Select the_geom INTO dij_point 
				                From network_tp_vertices_pgr 
				                Where id= dij_rec.id1;
						  IF ST_Intersects(prev_rec.segment,dij_segment)THEN
							dist1:=ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(closest_point_1),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(ST_Intersection(prev_rec.segment,dij_segment)),4326),26986));
                                                  END IF;
                                                 
					         
                                                 

						    IF first_dij THEN
								
								dij_sub := dij_rec.id2;
								dij_sub_segment := dij_segment;
								first_dij := 'f';

									IF dist1 >0 THEN
                        
									INSERT INTO speed VALUES (curr_rec.id,arg_traj,dij_point,ST_Y(dij_point),ST_X(dij_point),dij_rec.id2,dij_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,arg_pid);
									arg_pid :=arg_pid+1;
				
									

									END IF;

								ELSE
								
								 
								 --raise notice 'id %, s %, t %, s_id %, t_id %, dist2 %', arg_pid, arg_s,arg_t, dij_sub,curr_rec.segment_id, dist2;
								IF dij_rec.id2 != -1 THEN
								INSERT INTO speed VALUES (curr_rec.id,arg_traj,dij_point,ST_Y(dij_point),ST_X(dij_point),dij_sub,dij_sub_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,arg_pid);
								arg_pid :=arg_pid+1;

								ELSE
								dist2:=ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(closest_point_2),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(dij_point),4326),26986));
								
									IF dist2 >0 THEN
									INSERT INTO speed VALUES (curr_rec.id,arg_traj,dij_point,ST_Y(dij_point),ST_X(dij_point),dij_sub,dij_sub_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,arg_pid);
									arg_pid :=arg_pid+1;
	
									ELSE

									INSERT INTO speed VALUES (curr_rec.id,arg_traj,null,null,null,dij_sub,dij_sub_segment,dij_rec.seq,curr_rec.time_in_timestamp,curr_rec.epoch_time,'t',arg_day_of_week,arg_slot,null);
									END IF;

								END IF;
								
								dij_sub := dij_rec.id2;
								dij_sub_segment := dij_segment;


								END IF;

						
						  
						  
						
						  dist := dist+dij_rec.cost;
						  
							END IF;
							END IF;
        
					END LOOP;
				IF dist != 0 THEN	 
				        dist= dist+dist1+dist2;
				       
				        gap := (curr_rec.epoch_time-prev_rec.epoch_time);
				        IF gap < 20  and default_gap >0  THEN
                                        gap:= default_gap;
                                        Update segment set epoch_time= (prev_rec.epoch_time+default_gap) where id=curr_rec.id and traj_id=arg_traj;
                                        END IF;
                                        arg_speed := (dist*3.6)/ (gap);
                                 arg_day_of_week=EXTRACT (ISODOW from curr_rec.time_in_timestamp);
				 arg_slot= 100*EXTRACT (hour from curr_rec.time_in_timestamp)+EXTRACT (minute from curr_rec.time_in_timestamp);
				 adjust_time := prev_rec.epoch_time;
				 INSERT INTO speed VALUES (curr_rec.id,arg_traj,closest_point_2,ST_Y(closest_point_2),ST_X(closest_point_2),curr_rec.segment_id,segment2,arg_speed,curr_rec.time_in_timestamp,curr_rec.epoch_time,'f',arg_day_of_week,arg_slot,arg_pid);
				 arg_pid :=arg_pid+1;

				 For dij_rec IN SELECT * from speed  where id=curr_rec.id and traj_id=arg_traj and interpolate order by pid asc
                                 LOOP
				 IF dij_rec.speed =0 THEN

					

					adjust_time = adjust_time+(gap*dist1)/dist;
					SELECT to_timestamp(adjust_time)-interval '8 hour' into ad_time;
					arg_day_of_week=EXTRACT (ISODOW from ad_time);
					arg_slot= 100*EXTRACT (hour from ad_time)+EXTRACT (minute from ad_time);

					
                                 
					Update speed
					Set time_in_timestamp =ad_time, day_of_week=arg_day_of_week, time_slot= arg_slot,epoch_time = adjust_time
					Where pid=dij_rec.pid and id=curr_rec.id and traj_id=arg_traj;


                                 ELSE
					Select cost into dist1 from network_tp where id= dij_rec.segment_id;

					adjust_time = adjust_time+(gap*dist1)/dist;

					SELECT to_timestamp(adjust_time)-interval '8 hour' into ad_time;
					arg_day_of_week=EXTRACT (ISODOW from ad_time);
					arg_slot= 100*EXTRACT (hour from ad_time)+EXTRACT (minute from ad_time);
	
					
					

				 
					Update speed
					Set time_in_timestamp =ad_time, day_of_week=arg_day_of_week, time_slot= arg_slot,epoch_time = adjust_time
					Where pid=dij_rec.pid and id=curr_rec.id and traj_id=arg_traj;




                               

                                 END IF;
                                 END LOOP;


				 Update speed Set speed=arg_speed Where id=curr_rec.id and traj_id=arg_traj and interpolate;
                                 Update speed Set traj_id=0, id=arg_traj Where id=curr_rec.id and traj_id=arg_traj and interpolate and close_point is null ;
                                
			         ELSE
                                 --dijkstra fail
                                 END IF;
                               

			       END IF;  
                                 
                             
                              
                                 
                        --speed filter    
                      
                        
			select the_geom from data where id=prev_rec.id and traj_id =arg_traj into arg_s1_geom;
                        select the_geom from data where id=curr_rec.id and traj_id =arg_traj into arg_s2_geom;

                       
                        dist := ST_distance(arg_s1_geom,arg_s2_geom);

                       

			

			ELSE
			
			
			END IF;

				
		END IF;
		
		

                --change baseline point if speed is correct
		--IF not isolate THEN

		prev_rec:=curr_rec;
		
		Select raw_point From candidate
		Where id= curr_rec.id and traj_id=arg_traj INTO rp_1; 
		closest_point_1 := ST_ClosestPoint(prev_rec.segment,rp_1);
		
	
		--END IF;
                  
		
		END LOOP;
	



		select count(traj_id) into exist from exp where traj_id=arg_traj;
		select count(id) into total from data where  traj_id=arg_traj;
		select count(distinct(id)) into error from speed where  traj_id=arg_traj;

                firstpoint :=0;
                total_dist :=0;
		FOR curr_rec IN select close_point from speed where traj_id=arg_traj order by epoch_time
		LOOP

                    IF firstpoint =0 THEN  
                        prev_rec := curr_rec;
                        firstpoint :=1;
                    ELSE
			total_dist:=total_dist+ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(prev_rec.close_point),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(curr_rec.close_point),4326),26986));
                        --raise notice 'e% t%  ',ST_Distance(ST_Transform(ST_GeomFromText(ST_AsText(prev_rec.close_point),4326),26986),ST_Transform(ST_GeomFromText(ST_AsText(curr_rec.close_point),4326),26986)), total_dist;
			prev_rec := curr_rec;		 

                    END IF;
                         
                    
		END LOOP;
		

		raise notice 'e% t%  ',error, total_dist;



                IF exist = 1 THEN 
			IF total >1 THEN
			--rate:=1-(error/(total-1))::double precision;
			Update exp set exp3 = (error/total),point=total,length=total_dist where traj_id=arg_traj;
			ELSE
			Update exp set exp3 = -1 where traj_id=arg_traj;
			END IF;

		ELSE 
			IF total >1 THEN
			--rate:=1-(error/(total-1))::double precision;
			insert into exp (traj_id,exp3,point,length) values (arg_traj,error/total,total,total_dist);
			ELSE
			insert into exp (traj_id,exp3) values (arg_traj,-1);
			END IF;
		END IF;
				

		
		
        END;
        
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public."connect"(integer)
  OWNER TO postgres;
