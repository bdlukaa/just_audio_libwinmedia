import 'dart:async';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:libwinmedia/libwinmedia.dart';

/// The libwinmedia implementation of [JustAudioPlatform].
class LibWinMediaJustAudioPlugin extends JustAudioPlatform {
  final Map<String, LibWinMediaAudioPlayer> players = {};

  /// The entrypoint called by the generated plugin registrant.
  static void registerWith() {
    LWM.initialize();
    JustAudioPlatform.instance = LibWinMediaJustAudioPlugin();
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    if (players.containsKey(request.id)) {
      throw PlatformException(
        code: "error",
        message: "Platform player ${request.id} already exists",
      );
    }
    final player = LibWinMediaAudioPlayer(request.id);
    players[request.id] = player;
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    await players[request.id]?.dispose(DisposeRequest());
    players.remove(request.id);
    return DisposePlayerResponse();
  }
}

int _id = 0;

class LibWinMediaAudioPlayer extends AudioPlayerPlatform {
  List<StreamSubscription> streamSubscriptions = [];
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  final _dataEventController = StreamController<PlayerDataMessage>.broadcast();
  ProcessingStateMessage _processingState = ProcessingStateMessage.idle;
  Player player;
  double bufferingProgress = 0;

  LibWinMediaAudioPlayer(String id)
      : player = Player(id: _id),
        super(id) {
    _id++;

    void _handlePlaybackEvent(e) {
      broadcastPlaybackEvent();
    }

    final durationStream = player.streams.duration.listen(_handlePlaybackEvent);
    streamSubscriptions.add(durationStream);
    final indexStream = player.streams.index.listen(_handlePlaybackEvent);
    streamSubscriptions.add(indexStream);
    final bufferingStream = player.streams.isBuffering.listen((buffering) {
      if (buffering) {
        _processingState = ProcessingStateMessage.buffering;
      }
      _handlePlaybackEvent(buffering);
    });
    streamSubscriptions.add(bufferingStream);
    final completedStream = player.streams.isCompleted.listen((completed) {
      if (completed) {
        _processingState = ProcessingStateMessage.completed;
      }
      _handlePlaybackEvent(completed);
    });
    streamSubscriptions.add(completedStream);
    final playingStream = player.streams.isPlaying.listen((playing) {
      _processingState = ProcessingStateMessage.ready;
      _handlePlaybackEvent(playing);
    });
    streamSubscriptions.add(playingStream);
    final mediasStream = player.streams.medias.listen(_handlePlaybackEvent);
    streamSubscriptions.add(mediasStream);
    final positionStream = player.streams.position.listen(_handlePlaybackEvent);
    streamSubscriptions.add(positionStream);
    final errorStream = player.streams.error.listen((error) {
      if (error == null) return;
      switch (error.code) {
        case PlayerErrorCode.aborted:
          throw PlatformException(code: 'abort', message: error.message);
        default:
          throw PlatformException(
            code: '${error.code.index}',
            message: error.message,
          );
      }
    });
    streamSubscriptions.add(errorStream);
  }

  /// Broadcasts a playback event from the platform side to the plugin side.
  void broadcastPlaybackEvent() {
    if (player.downloadProgress != null) {
      bufferingProgress = player.downloadProgress!;
    }
    final updateTime = DateTime.now();
    _eventController.add(PlaybackEventMessage(
      processingState: _processingState,
      updatePosition: player.position,
      updateTime: updateTime,
      bufferedPosition: player.state.duration * bufferingProgress.clamp(0, 1),
      // TODO(libwinmedia): Icy Metadata
      icyMetadata: null,
      duration: player.state.duration,
      currentIndex: player.state.index.clamp(0, player.state.medias.length),
      androidAudioSessionId: null,
    ));
  }

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      _dataEventController.stream;

  List<Media> _loadAudioMessage(AudioSourceMessage sourceMessage) {
    final media = <Media>[];
    switch (sourceMessage.toMap()['type']) {
      case 'progressive':
      case 'dash':
      case 'hsl':
        final message = sourceMessage as UriAudioSourceMessage;
        media.add(Media(uri: message.uri));
        break;
      case 'silence':
        // final message = sourceMessage as SilenceAudioSourceMessage;
        throw UnsupportedError(
            'SilenceAudioSourceMessage is not a supported audio source.');
      case 'concatenating':
        final message = sourceMessage as ConcatenatingAudioSourceMessage;

        for (final source in message.children) {
          media.addAll(_loadAudioMessage(source));
        }
        break;
      case 'clipping':
        // final message = sourceMessage as ClippingAudioSourceMessage;
        throw UnsupportedError(
            'ClippingAudioSourceMessage is not a supported audio source.');
      case 'looping':
        // final message = sourceMessage as LoopingAudioSourceMessage;
        throw UnsupportedError(
            'LoopingAudioSourceMessage is not a supported audio source.');
    }
    return media;
  }

  /// Loads an audio source.
  @override
  Future<LoadResponse> load(LoadRequest request) {
    _processingState = ProcessingStateMessage.loading;
    final medias = _loadAudioMessage(request.audioSourceMessage);
    player.open(medias);
    return Future.value(LoadResponse(duration: null));
  }

  /// Plays the current audio source at the current index and position.
  @override
  Future<PlayResponse> play(PlayRequest request) {
    player.play();
    return Future.value(PlayResponse());
  }

  /// Pauses playback.
  @override
  Future<PauseResponse> pause(PauseRequest request) {
    player.pause();
    return Future.value(PauseResponse());
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    player.volume = request.volume;
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    player.rate = request.speed;
    return SetSpeedResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    if (request.position != null) {
      if (request.index != null) {
        player.jump(request.index!);
      }
      player.seek(request.position!);
    }
    return SeekResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    switch (request.loopMode) {
      case LoopModeMessage.one:
        player.isLooping = true;
        break;
      case LoopModeMessage.all:
        player.isAutoRepeat = true;
        player.isLooping = false;
        break;
      case LoopModeMessage.off:
        player.isLooping = false;
        player.isAutoRepeat = false;
        break;
    }
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
      SetShuffleModeRequest request) async {
    switch (request.shuffleMode) {
      case ShuffleModeMessage.all:
        player.isShuffling = true;
        break;
      case ShuffleModeMessage.none:
        player.isShuffling = false;
        break;
    }
    return SetShuffleModeResponse();
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
      ConcatenatingInsertAllRequest request) async {
    for (final child in request.children) {
      for (final messasgeChild in _loadAudioMessage(child)) {
        player.add(messasgeChild);
      }
    }
    return ConcatenatingInsertAllResponse();
  }

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
      ConcatenatingRemoveRangeRequest request) async {
    for (var i = request.startIndex; i < request.endIndex; i++) {
      player.remove(i);
    }
    return ConcatenatingRemoveRangeResponse();
  }

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
      ConcatenatingMoveRequest request) async {
    player.jump(request.newIndex);
    return ConcatenatingMoveResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    player.dispose();
    await _eventController.close();
    await _dataEventController.close();

    for (final sub in streamSubscriptions) {
      await sub.cancel();
    }

    return DisposeResponse();
  }
}
