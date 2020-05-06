#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  export DISPLAY=':99.0'
  sh -e /etc/init.d/xvfb start
  Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &
  sleep 3
fi
