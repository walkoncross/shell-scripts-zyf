for xx in {a..z}; do echo "${xx}* files"; ls -d ${xx}* | wc -l; done
for xx in {0..9}; do echo "${xx}* files"; ls -d ${xx}* | wc -l; done