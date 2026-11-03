seq 1 9 | xargs -L3
seq 1 9 | xargs -n3
seq 1 9 | xargs | xargs -L3
seq 1 9 | xargs | xargs -n3
cat arg.txt | xargs -I {} ./sk.sh -p {} -l
