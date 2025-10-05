set confirm off
set height unlimited
target extended-remote localhost:3333
monitor reset halt
load
monitor reset halt
shell sleep 1
run
quit
