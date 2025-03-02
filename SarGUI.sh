#!/bin/bash

# Function to clean up the link on exit
cleanup() {
    echo "Removing audio link..."
    if [[ -n "$input_device" && -n "$output_device" ]]; then
        pw-link -d "$input_device" "$output_device"
    fi
    exit 0
}

# Capture the exit signal (Ctrl+C or terminal close)
trap cleanup EXIT

# Check if PipeWire is running
if ! pw-cli info > /dev/null 2>&1; then
    zenity --error --text="PipeWire is not running. Please start PipeWire before continuing." --width=600 --height=400
    exit 1
fi

# Function to list available input devices
list_input_devices() {
    pw-cli list-objects Node | awk -F'"' '/node.name/ {print $2}' | grep -E "alsa_input|Audio/Source"
}

# Function to list available output devices
list_output_devices() {
    pw-cli list-objects Node | awk -F'"' '/node.name/ {print $2}' | grep -E "alsa_output|Audio/Sink"
}

# List input devices
input_list=$(list_input_devices)
if [ -z "$input_list" ]; then
    zenity --error --text="No input devices detected." --width=600 --height=400
    exit 1
fi

# Select input device
input_device=$(echo "$input_list" | zenity --list --title="Select an Input Device" --column="Device" --width=600 --height=400)
if [ -z "$input_device" ]; then
    zenity --error --text="No input device selected." --width=600 --height=400
    exit 1
fi

# List output devices
output_list=$(list_output_devices)
if [ -z "$output_list" ]; then
    zenity --error --text="No output devices detected." --width=600 --height=400
    exit 1
fi

# Select output device
output_device=$(echo "$output_list" | zenity --list --title="Select an Output Device" --column="Device" --width=600 --height=400)
if [ -z "$output_device" ]; then
    zenity --error --text="No output device selected." --width=600 --height=400
    exit 1
fi

# Link input device to output device via PipeWire
pw-link "$input_device" "$output_device"

if [ $? -eq 0 ]; then
    zenity --info --text="Audio is now routed from $input_device to $output_device.\nClick OK to stop." --width=600 --height=400
else
    zenity --error --text="Error linking devices." --width=600 --height=400
    exit 1
fi

# Clean up the link on exit
cleanup
