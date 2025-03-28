#!/bin/zsh

cd `git rev-parse --show-toplevel`

xcrun --run swift format --in-place --recursive Sources --configuration .swift-format --parallel
