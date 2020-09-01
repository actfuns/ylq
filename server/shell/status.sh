#!/bin/bash
echo 'directory root'
curdir=`pwd`
basedir=`echo "$curdir" | sed -s "s/\/trunk$//g"`
if [ -d $basedir/.git ] ; then
	git status
else
	svn status .
fi

echo 'directory daobiao'
svn status daobiao
