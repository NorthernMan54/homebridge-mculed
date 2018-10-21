#! /bin/sh

curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 0 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 10, \"value\": 100 }] }"
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 9, \"value\": true }] }"
sleep 1
echo "Off"
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 120 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
sleep 1
echo "On -2 "
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 240 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
sleep 1
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 60 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
sleep 1
echo "Off"
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 180 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
sleep 1
echo "On -2 "
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 300 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
sleep 1
curl -X PUT http://127.0.01:51826/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 9, \"value\": false }] }"
