if [ "$1" == "pre" ]
    then
    sudo chmod 666 /dev/ttyUSB0
    export MOTECOM=serial@/dev/ttyUSB0:telosb
elif [ "$1" == "station" ]
    then
    rm -r build
    make telosb install,300   #基站编号为1
elif [ "$1" == "listen" ]
    then
    java net.tinyos.tools.Listen
else
    echo "command not found"
fi