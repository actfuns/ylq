#!/bin/bash
while read line ; do
    echo "`date +%m-%d_%H-%M-%S`: ${line}"
done