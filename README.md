# BlindAssist

[![Build Status](https://travis-ci.org/BlindAssist/blindassist-ios.svg?branch=develop)](https://travis-ci.org/BlindAssist/blindassist-ios)
[![Stars](http://starveller.sigsev.io/api/repos/BlindAssist/blindassist-ios/badge)](http://starveller.sigsev.io/BlindAssist/blindassist-ios)
[![Coverage Status](https://coveralls.io/repos/github/BlindAssist/blindassist-ios/badge.svg?branch=develop)](https://coveralls.io/github/BlindAssist/blindassist-ios?branch=develop)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)

BlindAssist is an iOS application which has the goal to support blind people
on the road. Since I have a blind brother, I decided to create this open source
project.

## How does it work?

BlindAssist uses image segmentation to segment camera images in realtime. The
model used for this process is based on the
[cityscapes](https://www.cityscapes-dataset.com) dataset.

Besides CoreML, BlindAssist also runs ARKit to track the real world in 3D.
Several points in the 3D world (feature points) will be mapped to the
classes of the segmented image to determine it's correct class. A class
means an object, think of a road, car or bike.

This process will allow us to render and understand a world in 3d to make 
predicitions to the blind user. The inference results will be converted to 
sentences which will be spoken out loud by tts (text to speech).

You can run the `download_model.sh` script to get the prebuilt model.

The source of the model can be found here:
https://github.com/BlindAssist/blindassist-scripts

## In the media
<a href="https://heartbeat.fritz.ai/community-spotlight-blindassist-792b4211af42"><img src="https://fritz.ai/images/heartbeat_logo.png" alt="heartbeat" width="256"/></a>
