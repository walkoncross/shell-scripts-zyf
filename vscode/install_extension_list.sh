#!/bin/bash

while read -r extension; do
  code --install-extension "$extension"
done < vscode_extensions_list.txt