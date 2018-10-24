#! /bin/sh

trap ctrl_c INT
function ctrl_c() {
        echo "** Trapped CTRL-C"
	kill $mdns
}

OS=`uname -s`
if [[ "$OS" == 'Darwin' ]]; then
  dns-sd -R "My Test" _mculedProv._tcp. local 8266 &
  mdns=$!
elif [[ "$OS" == 'Linux' ]]; then
  avahi-publish  -R "My Test" _nodeProvision._tcp. 8266 &
  mdns=$!
fi

lua luaOTAserver.lua images
