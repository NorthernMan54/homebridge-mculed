local msg = "{ \"count\": 55, \"sensitivity\": 100}"
local json = require('json')

local table = json.parse(msg)

print( table["count"], table["sensitivity"])

if ( table["sensitivity"] ~= nil ) then
    print("sensitivity", table["sensitivity"])
end

local msg = "{ \"count\": 65}"

table = json.parse(msg)

print( table["count"], table["sensitivity"])
if ( table["sensitivity"] ~= nil )
then
    print("sensitivity", table["sensitivity"])
end

local msg = "55"

table = json.parse(msg)

print( table["count"], table["sensitivity"])
if ( table["sensitivity"] ~= nil )
then
    print("sensitivity", table["sensitivity"])
end
