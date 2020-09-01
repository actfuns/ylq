#!/bin/bash
curdir=`pwd`
basedir=`echo "$curdir" | sed -s "s/\/trunk$//g"`
if [ -d $basedir/.git ] ; then
	git svn rebase
else
	svn up .
fi

revertdirs=(daobiao/luadata daobiao/gamedata/server)
for dir in ${revertdirs[@]}; do
    for file in `svn st $dir|grep M|awk '{print $2}'` ; do
        svn revert $file
    done
done

svn up daobiao
