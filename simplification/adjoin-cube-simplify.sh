#!/bin/bash
# Ensure parameters are specified on the command-line
#set -x

if [ -z "$3" ]
then
    echo "Need instance filename, cube filename, and the index of the cube to adjoin (zero-based indexing)"
    exit
fi

n=$1
f=$2 #instance file name
c=$3 #cubes file name
i=$4 #index of cube
s=$5 #percentage of variable elimination
adj=$c$i.adj # Instance with adjoined cube
cnf=$c$i.cnf # Simplified instance
ext=$c$i.ext # Extension stack
cnfext=$c$i.cnfext # Simplified instance with extension stack

m=$((n*(n-1)/2)) # Number of edge variables in instance

# Determine the number of unit clauses to add
unitlines=0
for b in $(sed "$((i+1))q;d" "$c")
do
    if [[ "$b" != "a" && "$b" != "0" ]]
    then
        unitlines=$((unitlines+1))
    fi
done
numvars=$(head -n 1 "$f" | cut -d' ' -f3)
numlines=$(head -n 1 "$f" | cut -d' ' -f4)
newlines=$((numlines+unitlines))

# Write instance with adjoined cube
echo "p cnf $numvars $newlines" > "$adj"
tail "$f" -n +2 >> "$adj"

for b in $(sed "$((i+1))q;d" "$c")
do
    if [[ "$b" != "a" && "$b" != "0" ]]
    then
        echo "$b 0" >> "$adj"
    fi
done

# Use CaDiCaL to simplify instance with adjoined cube
./simplification/simplify-by-var-removal.sh "$adj" $s $m
