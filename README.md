# just_audio_libwinmedia

The [libwinmedia](https://github.com/harmonoid/libwinmedia/tree/master/flutter#libwinmediadart) implementation of [`just_audio`](https://github.com/ryanheise/just_audio).

## ⚠️ Deprecated

The project is now archived. The library that is used by this plugin to implement the audio playback features ([libwinmedia](https://github.com/harmonoid/libwinmedia)) is now deprecated, which makes impossible to continue to maintain this plugin. 

- **Inefficient Linux support**: using WebKit limits the possibilities of audio management
- **Unnecessary abstraction**: it's better to make separated implementations
- **Unsafe**: crashes due to JS interop
- **No backward compatibility**: only Windows 10+ is supported
- **No embedded Linux support**: it cannot be used on non-GTK Flutter embedders like flutter-pi

### So, what to use?

For Windows, you can use [just_audio_windows](https://pub.dev/packages/just_audio_windows), which is a just_audio implementation using native code for windows.

For Linux, you can use [just_audio_mpv](https://pub.dev/packages/just_audio_mpv), which uses `mpv_dart`

## Installation

Add the [just_audio_libwinmedia](https://pub.dev/packages/just_audio_libwinmedia) dependency to your `pubspec.yaml` alongside with `just_audio`:

```yaml
dependencies:
  just_audio: any # substitute version number
  just_audio_libwinmedia: any # substitute version number
```

### Linux

Install the required packages before building your app.

```
sudo apt-get install libwebkit2gtk-4.0-dev
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
