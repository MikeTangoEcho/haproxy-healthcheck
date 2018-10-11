haproxy-healthcheck
========

*EXPERIMENTAL*

Lua script to manage stats collection and reporting to third parties.

Currenty supported:
* sentry

Prerequisites
=============

Tested on Docker haproxy:1.8 with lua 5.3 and luarocks 2.4.2

```
    apt-get update
    apt-get install lua5.3 liblua5.3-dev libssl-dev
    apt-get install luarocks
```

Install lua-cjson 2.1.0 because last version require lua5.3 to be build with 5.1 compat, and the lua in the repo was not built this way
If you have compiled your lua5.3 with 5.1 compat you can modify the rockspec file to remove the version requirement on cjson dependency
```sh
    cd modules/raven-lua
    luarocks make
```
