onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib RAM_Line_opt

do {wave.do}

view wave
view structure
view signals

do {RAM_Line.udo}

run -all

quit -force
