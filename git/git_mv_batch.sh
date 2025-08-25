find . -name '*tts_voice_list*' -exec bash -c '
  for file; do
    new_file="${file//tts_voice_list/tts_voices}"
    if [ "$file" != "$new_file" ]; then
      git mv -- "$file" "$new_file"
    fi
  done
' bash {} +

find . -name 'xiling*' -exec bash -c '
  for file; do
    new_file="${file//xiling/baidu_xiling}"
    if [ "$file" != "$new_file" ]; then
      git mv -- "$file" "$new_file"
    fi
  done
' bash {} +