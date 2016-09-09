#!/bin/bash
#program:
#candidate_test sep  .e_bus_sep...table. candidate_test

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#mkdir only if a dir does not already exist
mkdir -p /home/mikelin/scripts/



#creat_tablename_array ()
#count jobs number
i=0
t=(3 7 10 12 14 24 25 29 34 48 51 69 73 77 111 113 124 135 140 148 160 171 197 245 263 336 339 341 437 441 14 15
26 34 48 69 77 93 95 111 113 123 124 135 140 148 150 160 171 197)


a=49

j=7
jobs > /tmp/jobs.txt
w=$(wc -l < /tmp/jobs.txt)



#while(i < table_name_array..)

while [ $i -lt $a ]
do
#while(i<table_name_array.. && work ....$3)
        while [ $w -lt $j ] && [ $i -lt $a ]
        do
                echo "w in 2 : $w, $i"
                echo "t = ${t[$i]}"

                echo Usr_pw | nohup time sudo -S -u postgres psql -U postgres -d e_bus  -c "( SELECT candidate(${t[$i]}))"&

                ((i++))
                jobs > /tmp/jobs.txt
                w=$(wc -l < /tmp/jobs.txt)

        done
        jobs > /tmp/jobs.txt
        w=$(wc -l < /tmp/jobs.txt)
        sleep 3s
done
