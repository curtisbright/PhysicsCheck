#!/bin/bash
#set -x
# Ensure parameters are specified on the command-line
if [ -z "$2" ]
then
	echo "Need filename, order, and the number of conflicts for which to simplify"
	exit
fi

f=$1
o=$2
m=$3

# Directory to log simplification output
mkdir -p log

# Directory for simplified output
mkdir -p simp

# Simplify m seconds
echo "simplifying for $m conflicts"
i=1
./cadical/build/cadical "$f" -o simp/"$f".simp1 -e simp/"$f".ext1 -n -c $m | tee log/"$f".simp1
str=$(less log/"$f".simp1 | grep "c conflicts:")
conf_used=$(echo $str | awk -F ' ' '{print $3; exit;}')
echo "$conf_used conflicts used for simplification"
if grep -q "UNSATISFIABLE" log/"$f".simp1
then
	conf_left=0
else
	conf_left=$(echo $m-$conf_used | bc)
fi
while [ $(echo "$conf_used < $m" | bc) -ne 0 ] && [ "$conf_left" != 0 ]
do
	conf_left=$(echo $m-$conf_used | bc)
	./cadical/build/cadical simp/"$f".simp"$i" -o simp/"$f".simp$((i+1)) -e simp/"$f".ext$((i+1)) -n -c $conf_left | tee log/"$f".simp$((i+1))
	str=$(less log/"$f".simp$((i+1)) | grep "c conflicts:")
	conf_used_2=$(echo $str | awk -F ' ' '{print $3; exit;}')
	conf_used=$(echo $conf_used+$conf_used_2 | bc)
	echo "$conf_used conflicts used for simplification"
	((i+=1))
	if grep -q "UNSATISFIABLE" log/"$f".simp$i
	then
		break
	fi
done

m=$i
echo "Called CaDiCaL $m times"

# Number of variables and lines in the final simplified instance
numvars=$(head -n 1 simp/"$f".simp"$m" | cut -d' ' -f3)
numlines=$(head -n 1 simp/"$f".simp"$m" | cut -d' ' -f4)

# Lines in reconstruction stack
extlines_total=0

e=$((o*(o-1)/2))
for i in $(seq 1 "$m")
do
	extlines_i=$(awk "sqrt(\$(NF-1)*\$(NF-1))<=$e" "simp/"$f".ext$i" | wc -l | cut -d' ' -f1)
	extlines_total=$((extlines_total+extlines_i))
done

# Lines in simplified instance with reconstruction stack
newlines=$((numlines+extlines_total))

# Output final simplified instance
echo "p cnf $numvars $newlines" > "$f".simp
tail simp/"$f".simp"$m" -n +2 >> "$f".simp
for i in $(seq 1 "$m")
do
	awk "sqrt(\$(NF-1)*\$(NF-1))<=$e" "simp/"$f".ext$i" | sed 's/ 0.*/ 0/' >> "$f".simp
done