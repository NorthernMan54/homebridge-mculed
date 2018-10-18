#! /bin/sh

trap ctrl_c INT
function ctrl_c() {
        echo "** Trapped CTRL-C"
	kill $mdns
}

if [[ "$OSTYPE" == 'darwin18' ]]; then
  dns-sd -R "My Test" _mculedProv._tcp. local 8266 &
  mdns=$!
elif [[ "$OSTYPE" == 'linux-gnueabihf' ]]; then
  dns-sd -R "My Test" _nodeProvision._tcp. local 8266 &
  mdns=$!
fi

lua luaOTAserver.lua images
