#!/bin/bash

WORKSPACE=$(cd $(dirname $0)/; pwd)
cd $WORKSPACE

mkdir -p var

app=blog
pidfile=var/app.pid
logfile=var/app.log

function check_pid() {
    if [ -f $pidfile ];then
        pid=`cat $pidfile`
        if [ -n $pid ]; then
            running=`ps -p $pid|grep -v "PID TTY" |wc -l`
            return $running
        fi
    fi
    return 0
}

function build() {
    version=`git tag | head -1`
    gitversion=`git log --format='%h' | head -1`
    buildtime=`date +%Y-%m-%d_%H:%M:%S`
    CGO_ENABLED=1 GOOS=linux go build -v -a -installsuffix cgo -ldflags "-X duguying/$app/g.GitVersion=$gitversion -X duguying/$app/g.BuildTime=$buildtime" -o $app .
}

function pack() {
    version=`git tag | head -1`
    rm -rf release
    rm -rf dist
    rm -f release-${version}.zip
    mkdir release
    mkdir dist
    cp blog release/
    cp -r static release/
    zip -r dist/release-${version}.zip release/
}

function start() {
    check_pid
    running=$?
    if [ $running -gt 0 ];then
        echo -n "$app now is running already, pid="
        cat $pidfile
        return 1
    fi


    nohup ./$app >> $logfile &
    echo $! > $pidfile
    echo "$app started..., pid=$!"
}

function stop() {
    pid=`cat $pidfile`
    kill $pid
    echo "$app stoped..."
}

function restart() {
    stop
    sleep 1
    start
}

function status() {
    check_pid
    running=$?
    if [ $running -gt 0 ];then
        echo started
    else
        echo stoped
    fi
}

function tailf() {
    tail -f $logfile
}

function help() {
    echo "$0 build|pack|start|stop|restart|status|tail"
}

if [ "$1" == "" ]; then
    help
elif [ "$1" == "build" ];then
    build
elif [ "$1" == "stop" ];then
    stop
elif [ "$1" == "start" ];then
    start
elif [ "$1" == "restart" ];then
    restart
elif [ "$1" == "status" ];then
    status
elif [ "$1" == "tail" ];then
    tailf
elif [ "$1" == "pack" ];then
    pack
else
    help
fi