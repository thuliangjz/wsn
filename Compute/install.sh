if [ "$1" == "pre" ]
    then
    sudo chmod 666 /dev/ttyUSB0
    export MOTECOM=serial@/dev/ttyUSB0:telosb
elif [ "$1" == "main" ]
    then
    rm -r build
    make -f MakeMain telosb install,300   #主节点编号300
elif [ "$1" == "assist" ]
    then
    rm -r build
    make -f MakeAssist telosb install,200   #修改辅节点编号时注意修改defs.h中的ASSIST_NODE_IDS
else
    echo "command not found"
fi