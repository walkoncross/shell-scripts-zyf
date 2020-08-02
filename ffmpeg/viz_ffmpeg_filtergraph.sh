#!/bin/bash
## Author: zhaoyafei0210@gmail.com

filtergraph='[1:v][0:v] scale2ref=w=-2:h=ih [rightvid][leftvid]; [leftvid][rightvid] hstack [outvid]'
if [[ $# -gt 0 ]]; then
    filtergraph=$@
fi

echo $filtergraph | \
graph2dot -o graph.tmp && \
dot -Tpng graph.tmp -o graph.png