#!/bin/bash

# this script is to support use of formulas like hadoop-formula and accumulo-formula
# that rely on but come without ssh keypair files
# set -x

cd $(dirname $0)
bindir=$(pwd)
cd - 2>/dev/null

generator=${bindir}/generate_keypairs.sh
if [ -d /srv/salt ] 
then
	for formula in hadoop
	do
		[ ! -d /srv/salt/${formula}/files ] && mkdir -p /srv/salt/${formula}/files
		cd /srv/salt/${formula}/files
		if [ $formula == hadoop ]
		then
                  ${generator} 
		else
		  ${generator} ${formula}
		fi
	done
else
	echo "This script needs to be executed on your salt master"
fi	
