if [ "$1" == "pre" ]
    then
    sudo chmod 666 /dev/ttyUSB0
    export MOTECOM=serial@/dev/ttyUSB0:telosb
else
    make telosb install,100
fi