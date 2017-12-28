if [ "$1" == "pre" ]
    then
    sudo chmod 666 /dev/ttyUSB0
    export MOTECOM=serial@/dev/ttyUSB0:telosb
elif [ "$1" == "main" ]
    then
    rm -r build
    make -f MakeMain telosb install,6   #主节点编号6
elif [ "$1" == "assist" ]
    then
    rm -r build
    make -f MakeAssist telosb install,4   #辅节点4，5 修改辅节点编号时注意修改defs.h中的ASSIST_NODE_IDS
elif [ "$1" == "l" ]
    then
    java net.tinyos.tools.PrintfClient
else
    echo "command not found"
fi