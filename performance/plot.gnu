set terminal pngcairo transparent enhanced font "arial,10" fontscale 1.0 size 800, 600 
set output "plot.png"
set key bmargin left horizontal Right noreverse enhanced autotitle
#set minussign
set samples 800, 800
set title "Performance Array Decision Procedure" 
set title  font ",20" norotate
set ylabel "time taken by decision procedure (s)"
set xlabel "number of accesses"
#x = 0.0
plot [0:300] 'array_read1.dat' with lines title 'Constant index read',\
             'array_write1.dat' with lines title 'Constant index write'



