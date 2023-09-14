#!/bin/bash -e

# Read config
. config.sh
# Cross build functions
. common/functions/relative_source.sh
relative_source common/functions/cross.sh
cross