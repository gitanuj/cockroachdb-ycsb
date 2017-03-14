set output "latencies.eps"
set term postscript eps size 4.0,2.6 enhanced color font 'Helvetica,16' lw 2
set xlabel "Lease Holder Read Percentage"
set ylabel "Avg Update Latency (us)"
set y2label "Avg Read Latency (us)"
set ytics nomirror
set y2tics nomirror
set key outside above

plot "2.dat" using 1:2 with lp ps 1.6 pt 1 lc 1 lt 1 title "Quorum Avg Update Latency", \
"3.dat" using 1:2 with lp ps 1.6 pt 2 lc 2 lt 2 title "Strongly Consistent Quorum Avg Update Latency", \
"2.dat" using 1:3 with lp ps 1.6 pt 4 lc 4 lt 4 title "Quorum Avg Read Latency" axes x1y2, \
"3.dat" using 1:3 with lp ps 1.6 pt 6 lc 6 lt 6 title "Strongly Consistent Quorum Avg Read Latency" axes x1y2
