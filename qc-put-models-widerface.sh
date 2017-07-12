tar czvf frcn-models-widerface.tar.gz models/widerface
qrsctl login pulp@qiniu.com Bob_dylon456
qrsctl put face-models  frcn-models-widerface.tar.gz  frcn-models-widerface.tar.gz 
