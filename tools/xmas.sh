#! /bin/sh

SLEEP=5

HOST="bart:51826"

echo "\nRED"
curl -X PUT http://$HOST/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 9, \"value\": true }] }"
curl -X PUT http://$HOST/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 0 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
curl -X PUT http://$HOST/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 10, \"value\": 100 }] }"
sleep $SLEEP
echo "\nGREEN"
curl -X PUT http://$HOST/characteristics --header "Content-Type:Application/json" --header "authorization: 031-45-154" --data "{ \"characteristics\": [{ \"aid\": 2, \"iid\": 11, \"value\": 120 },{ \"aid\": 2, \"iid\": 12, \"value\": 100 }] }"
sleep $SLEEP
