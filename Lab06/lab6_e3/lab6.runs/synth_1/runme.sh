#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/run/media/alvinna/2c7f4a2c-2eeb-4b78-ad1f-f4d2e6476847/opt/Xilinx/Vivado/2019.1/ids_lite/ISE/bin/lin64:/run/media/alvinna/2c7f4a2c-2eeb-4b78-ad1f-f4d2e6476847/opt/Xilinx/Vivado/2019.1/bin
else
  PATH=/run/media/alvinna/2c7f4a2c-2eeb-4b78-ad1f-f4d2e6476847/opt/Xilinx/Vivado/2019.1/ids_lite/ISE/bin/lin64:/run/media/alvinna/2c7f4a2c-2eeb-4b78-ad1f-f4d2e6476847/opt/Xilinx/Vivado/2019.1/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/Alvinna/Desktop/lab6/lab6.runs/synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log lab6_tb.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source lab6_tb.tcl
