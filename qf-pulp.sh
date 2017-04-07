echo $@

if [ $# -lt 1 ]; then
	echo "Error: No bucket"
fi
bkt=$1

if [ $# -gt 1 ]; then
	file=$2
else
	file=qf-list.txt
fi

qfetch -ak="F92-G4jA5CkT-eibTAtosv6ETVqhpzaGoVtdsTGM" -sk="aCQJhOuPEooQGUV56VB7VH6CPFNCzwWZmhBQkA5i" -bucket="$bkt" -file="$file" -worker=300 -job="qfetch_pulp"
