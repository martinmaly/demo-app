#!/usr/bin/env bash

while IFS="=" read -r key value; do
  if [[ -n "${key}" ]]; then
    echo "Replacing ${key} --> ${value}"
    grep -rl '\$\$'"$key"'\$\$' ./* | xargs --verbose --no-run-if-empty sed -i 's/\$\$'"$key"'\$\$/'"$value"'/g'
  fi
done <specialize.vars

exit 0
