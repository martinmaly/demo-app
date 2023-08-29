#!/usr/bin/env bash

while IFS="=" read -r key value; do
  echo "Replacing ${key} --> ${value}"
  grep -rl '\$\$'"$key"'\$\$' ./* | xargs sed -i 's/\$\$'"$key"'\$\$/'"$value"'/g'
done <specialize.vars
