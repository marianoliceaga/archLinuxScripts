#!/bin/bash

# Start Carla with your project file
pw-jack carla-rack --no-gui "$HOME/amp_gain4.carxp" &
CARLA_PID=$!

# Wait for Carla ports to appear
echo "⏳ Waiting for Carla ports..."
TRIES=10
until pw-link -l | grep -q "Carla:audio-in1" || [ $TRIES -eq 0 ]; do
    sleep 2
    ((TRIES--))
done

if [ $TRIES -eq 0 ]; then
    echo "❌ Carla ports unavailable. Exiting."
    kill "$CARLA_PID"
    exit 1
fi

# Connect Brave and Bitwig to Carla inputs (mixed)
pw-link "Brave:output_FL" "Carla:audio-in1"
pw-link "Brave:output_FR" "Carla:audio-in2"
pw-link "Bitwig Studio:out1" "Carla:audio-in1"
pw-link "Bitwig Studio:out2" "Carla:audio-in2"

# Connect Carla outputs to UMC404HD playback
pw-link "Carla:audio-out1" "UMC404HD 192k Direct UMC404HD 192k:playback_FL"
pw-link "Carla:audio-out2" "UMC404HD 192k Direct UMC404HD 192k:playback_FR"

echo "✅ Brave and Bitwig audio successfully amplified through Carla."
