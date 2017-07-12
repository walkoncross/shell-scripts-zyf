tar czvf py-frcn-train-output.tar.gz output
qrsctl login pulp@qiniu.com Bob_dylon456
qrsctl put face-models py-frcn-train-output.tar.gz py-frcn-train-output.tar.gz
