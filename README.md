# BlindAssist
[![Build Status](https://travis-ci.com/BlindAssist/blindassist-ios.svg?branch=develop)](https://travis-ci.com/BlindAssist/blindassist-ios)
[![Stars](http://starveller.sigsev.io/api/repos/BlindAssist/blindassist-ios/badge)](http://starveller.sigsev.io/BlindAssist/blindassist-ios)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)

BlindAssist is an iOS application which has the goal to support blind people
on the road. Since I have a blind brother, I decided to create this open source
project.

## Videos
[![BlindAssist](https://img.youtube.com/vi/eb-ESNV_PEI/0.jpg)](https://www.youtube.com/watch?v=eb-ESNV_PEI "BlindAssist")
[![BlindAssist ARKit](https://img.youtube.com/vi/t-L0bm0pySU/0.jpg)](https://www.youtube.com/watch?v=t-L0bm0pySU "BlindAssist ARKit")

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
[![Fritz](images/fritz_logo.png?raw=true)](https://fritz.ai)
