#!/bin/bash
snap() { awk 'NR==1{total=0; for(i=2;i<=NF;i++) total+=$i; print total, $5+$6}' /proc/stat; }
read t1 i1 <<< $(snap)
sleep 1
read t2 i2 <<< $(snap)
dt=$(( t2 - t1 ))
di=$(( i2 - i1 ))
(( dt > 0 )) && echo $(( 100 - di * 100 / dt )) || echo 0
