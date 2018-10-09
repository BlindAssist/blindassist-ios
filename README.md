# BlindAssist
[![Build Status](https://app.bitrise.io/app/8cef371afcc71242/status.svg?token=shtpwFUA6aLw-ky-oBJP2g&branch=develop)](https://app.bitrise.io/app/8cef371afcc71242)
[![Stars](http://starveller.sigsev.io/api/repos/BlindAssist/blindassist-ios/badge)](http://starveller.sigsev.io/BlindAssist/blindassist-ios)
[![Coverage Status](https://coveralls.io/repos/github/BlindAssist/blindassist-ios/badge.svg?branch=develop)](https://coveralls.io/github/BlindAssist/blindassist-ios?branch=develop)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)

BlindAssist is an iOS application which has the goal to support blind people
on the road. Since I have a blind brother, I decided to create this open source
project.

## How does it work?
The assisting process will be done using deep learning, image segmentation
and translating the inference results to sentences which will be spoken out loud 
by tts (text to speech). The model used for this process is based on the
[cityscapes](https://www.cityscapes-dataset.com) dataset.

Currently BlindAssist uses CoreML. You can run the `download_model.sh` script to
get the prebuilt model.

The source of the model can be found here:
https://github.com/BlindAssist/blindassist-scripts

## Sponsors
<a href="https://heartbeat.fritz.ai"><img src="https://fritz.ai/images/heartbeat_logo.png" alt="heartbeat" width="256"/></a>
