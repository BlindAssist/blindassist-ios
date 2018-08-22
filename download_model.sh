#!/bin/bash

OUTPUT_DIR="./BlindAssist/cityscapes.mlmodel"
MODEL_URL="https://github.com/BlindAssist/blindassist-scripts/releases/download/v1.0/cityscapes.mlmodel"

echo "Starting mlmodel download..."

# Download the BlindAssist CoreML model
# from the latest repos release and place
# it in the correct location
wget -O $OUTPUT_DIR $MODEL_URL

echo "Done downloading"
