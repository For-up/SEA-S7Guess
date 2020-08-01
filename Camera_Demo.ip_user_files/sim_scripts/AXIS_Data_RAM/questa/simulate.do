onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib AXIS_Data_RAM_opt

do {wave.do}

view wave
view structure
view signals

do {AXIS_Data_RAM.udo}

run -all

quit -force
