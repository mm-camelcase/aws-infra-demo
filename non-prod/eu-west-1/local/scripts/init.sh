#!/bin/bash

# Function to remove .terragrunt-cache directories and .terraform.lock.hcl files
remove_items(){
    local base_dir=$1

    # Find and remove .terragrunt-cache directories
    find "$base_dir" -type d -name '.terragrunt-cache' -exec rm -rf {} + 2>/dev/null

    # Find and remove .terraform.lock.hcl files
    find "$base_dir" -type f -name '.terraform.lock.hcl' -exec rm -f {} + 2>/dev/null
}


docker restart localstack

# Set the base directory to local
BASE_DIR="../../local"

# Call the function to remove items
remove_items "$BASE_DIR"