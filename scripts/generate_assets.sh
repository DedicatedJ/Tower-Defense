#!/bin/bash

# Create scripts directory if it doesn't exist
mkdir -p scripts

# Run the placeholder generator
love . scripts/generate_placeholders.lua

echo "Asset generation complete!" 