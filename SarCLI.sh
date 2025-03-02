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
    echo "PipeWire is not running. Please start PipeWire before continuing."
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
echo "Detected input devices:"
echo "$input_list"
if [ -z "$input_list" ]; then
    echo "No input devices detected."
    exit 1
fi

# Select input device
echo "Select an input device:"
select input_device in $input_list; do
    if [ -n "$input_device" ]; then
        break
    fi
    echo "Invalid selection. Please choose a valid number."
done

# List output devices
output_list=$(list_output_devices)
echo "Detected output devices:"
echo "$output_list"
if [ -z "$output_list" ]; then
    echo "No output devices detected."
    exit 1
fi

# Select output device
echo "Select an output device:"
select output_device in $output_list; do
    if [ -n "$output_device" ]; then
        break
    fi
    echo "Invalid selection. Please choose a valid number."
done

# Link input device to output device via PipeWire
pw-link "$input_device" "$output_device"

if [ $? -eq 0 ]; then
    echo "Audio is now routed from $input_device to $output_device."
    read -p "Press Enter to stop..."
else
    echo "Error linking devices."
    exit 1
fi

# Clean up the link on exit
cleanup
