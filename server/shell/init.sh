#!/bin/bash

rm -Rf daobiao
now_url=`svn info | grep 'URL' | grep 'https' | awk '{print $NF}'`
daobiao_url=${now_url//server/doc}'/daobiao'
echo $daobiao_url
svn checkout $daobiao_url daobiao

chmod -R 777 shell
