#!/bin/bash
## author: zhaoyafei0210@gmail.com

rsync --progress -avz \
  --timeout=300 \
  --inplace --partial \
    $1 $2
