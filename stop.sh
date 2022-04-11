#!/bin/bash

ps -ef | grep 'dumpster_diver.sh' | grep -v grep | awk '{print $2}' | xargs -r kill -9