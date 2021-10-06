# just_audio_libwinmedia

The [libwinmedia](https://github.com/harmonoid/libwinmedia/tree/master/flutter#libwinmediadart) implementation of [`just_audio`][https://github.com/ryanheise/just_audio].

## Installation

Add the [just_audio_libwinmedia](https://pub.dev/packages/just_audio_libwinmedia) dependency to your `pubspec.yaml` alongside with `just_audio`:

```yaml
dependencies:
  just_audio: any # substitute version number
  just_audio_libwinmedia: any # substitute version number
```

## Features

| Feature                        | Windows | Linux |
| ------------------------------ | :-----: | :---: |
| read from URL                  |   ✅    |  ✅   |
| read from file                 |   ✅    |  ✅   |
| read from asset                |   ✅    |  ✅   |
| read from byte stream          |         |       |
| request headers                |         |       |
| DASH                           |   ✅    |       |
| HLS                            |   ✅    |       |
| ICY metadata                   |         |       |
| buffer status/position         |   ✅    |  ✅   |
| play/pause/seek                |   ✅    |  ✅   |
| set volume/speed               |   ✅    |  ✅   |
| clip audio                     |         |       |
| playlists                      |   ✅    |  ✅   |
| looping/shuffling              |   ✅    |  ✅   |
| compose audio                  |         |       |
| gapless playback               |   ✅    |       |
| report player errors           |   ✅    |  ✅   |
| handle phonecall interruptions |         |       |
| buffering/loading options      |         |       |
| set pitch                      |         |       |
| skip silence                   |         |       |
| equalizer                      |         |       |
| volume boost                   |         |       |
