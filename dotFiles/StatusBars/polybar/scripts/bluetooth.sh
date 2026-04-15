#!/bin/bash

# Bluetooth status script for Polybar

if command -v bluetoothctl &> /dev/null; then
    power_status=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
    
    if [ "$power_status" = "yes" ]; then
        # Check if any device is connected
        connected=$(bluetoothctl info | grep "Connected: yes" | wc -l)
        
        if [ "$connected" -gt 0 ]; then
            echo "󰂯 on"
        else
            echo "󰂲 on"
        fi
    else
        echo "󰂲 off"
    fi
else
    echo "󰂲 n/a"
fi
