#!/usr/bin/env bash

echo Parallels ................................................................
echo deleting potential Application Parallels directory...
cd 
[ -d  'Applications (Parallels)' ] && echo '    Directory found'
[ ! -d  'Applications (Parallels)' ] && echo '    Directory not found'
rm -vfr Applications\ \(Parallels\)/
