fa=('1 2 3' '4 5 6' '7 8 9')
printf '%s\n' "${fa[@]}" | xargs -n 3 sh -c 'echo call_my_command --arg1="$1" --arg2="$2" --arg3="$3"' argv0
printf '%s\n' "${fa[@]}" | cut -d' ' -f1,2,3 | xargs -n 3 bash -c 'echo $0 $1 $2'


