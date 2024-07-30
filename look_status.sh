#!/bin/bash

if [[ $(docker ps -qf name=nwaku) ]]; then
    echo "waku正在运行"
else
    echo "停止"
fi
