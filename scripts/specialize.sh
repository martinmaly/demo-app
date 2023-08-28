#!/usr/bin/env bash

while IFS="=" read -r key value; do
    grep -rl '\$\$'"$key"'\$\$' ./* | xargs sed -i 's/\$\$'"$key"'\$\$/'"$value"'/g'
done <specialize.vars