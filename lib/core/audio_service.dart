import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'reminder_state.dart';
import 'notification_service.dart';

enum ActiveAudio { none, exhale, tatastha, chime }

/// Handles all audio playback with sequential queueing, volume management, and mode handling.
class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  ActiveAudio _currentSound = ActiveAudio.none;
  final List<_QueuedAudio> _queue = [];
  bool _isProcessingQueue = false;
  bool _isBusy = false;

  AudioService() {
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setVolume(1.0);
    } catch (_) {}

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onAudioCompleted();
      }
      notifyListeners();
    });
  }

  ActiveAudio get currentSound => _currentSound;
  bool get isPlaying =>
      _player.playing &&
      _player.playerState.processingState != ProcessingState.completed;
  bool get isPlayingExhale => isPlaying && _currentSound == ActiveAudio.exhale;
  bool get isPlayingTatastha => isPlaying && _currentSound == ActiveAudio.tatastha;

  void attach(AppState state) {
    state.onExhale = () => _handleExhaleTrigger(state);
    state.onTatastha = () => _handleTatasthaTrigger(state);
    state.onBothReminders = () => _handleBothTrigger(state);
    state.onTaste = () => _handleTatasthaTrigger(state);
  }

  // ── Scheduler Handlers ─────────────────────────────────────────────────────
  Future<void> _handleExhaleTrigger(AppState state) async {
    if (state.isEffectivelyPaused() ||
        state.notificationMode == NotificationMode.silent) {
      return;
    }
    if (state.notificationMode == NotificationMode.vibrationOnly) {
      await NotificationService.triggerVibration();
      return;
    }
    await NotificationService.triggerVibration();
    await enqueueSound(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
  }

  Future<void> _handleTatasthaTrigger(AppState state) async {
    if (state.isEffectivelyPaused() ||
        state.notificationMode == NotificationMode.silent) {
      return;
    }
    if (state.notificationMode == NotificationMode.vibrationOnly) {
      await NotificationService.triggerVibration();
      return;
    }
    await NotificationService.triggerVibration();
    await enqueueSound(ActiveAudio.tatastha, 'assets/audio/tatastha.mp3');
  }

  Future<void> _handleBothTrigger(AppState state) async {
    if (state.isEffectivelyPaused() ||
        state.notificationMode == NotificationMode.silent) {
      return;
    }
    if (state.notificationMode == NotificationMode.vibrationOnly) {
      await NotificationService.triggerVibration();
      return;
    }
    await NotificationService.triggerVibration();
    // Play Exhale, and queue Tatastha to play sequentially immediately after
    _queue.clear();
    _queue.add(const _QueuedAudio(
      sound: ActiveAudio.tatastha,
      asset: 'assets/audio/tatastha.mp3',
    ));
    await _playDirect(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
  }

  /// Plays sound immediately or queues it so audios play sequentially without overlapping
  Future<void> enqueueSound(ActiveAudio sound, String asset) async {
    if (isPlaying || _isBusy || _isProcessingQueue) {
      // Avoid duplicate entries for same sound
      _queue.removeWhere((item) => item.sound == sound);
      _queue.add(_QueuedAudio(sound: sound, asset: asset));
      return;
    }
    await _playDirect(sound, asset);
  }

  /// Queue a sound to play after the current one finishes (for sequential exhale→tatastha)
  void queueNext(ActiveAudio sound, String asset) {
    // Remove any existing entry for this sound to avoid duplicates
    _queue.removeWhere((item) => item.sound == sound);
    _queue.add(_QueuedAudio(sound: sound, asset: asset));
  }

  Future<void> _playDirect(ActiveAudio sound, String asset) async {
    if (_isBusy) {
      _queue.removeWhere((item) => item.sound == sound);
      _queue.add(_QueuedAudio(sound: sound, asset: asset));
      return;
    }
    _isBusy = true;
    try {
      _currentSound = sound;
      await _player.stop();
      try {
        await _player.setAsset(asset);
      } catch (_) {
        final fallback = asset.endsWith('.mp3')
            ? asset.replaceAll('.mp3', '.mpeg')
            : 'assets/audio/reminder.mpeg';
        await _player.setAsset(fallback);
      }
      await _player.seek(Duration.zero);
      await _player.setVolume(1.0);
      await _player.play();
      notifyListeners();
    } catch (_) {
      _currentSound = ActiveAudio.none;
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }

  void _onAudioCompleted() {
    _currentSound = ActiveAudio.none;
    if (_queue.isNotEmpty && !_isProcessingQueue) {
      _isProcessingQueue = true;
      Future.delayed(const Duration(milliseconds: 700), () async {
        if (_queue.isNotEmpty) {
          final next = _queue.removeAt(0);
          await _playDirect(next.sound, next.asset);
        }
        _isProcessingQueue = false;
      });
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _queue.clear();
    _isProcessingQueue = false;
    _currentSound = ActiveAudio.none;
    try {
      if (_player.playing) {
        await _player.stop();
      }
    } catch (_) {}
    notifyListeners();
  }

  // ── Manual Trigger Play/Stop (for test buttons) ─────────────────────────────
  Future<void> playExhale([AppState? state]) async {
    if (isPlayingExhale) {
      await stop();
      return;
    }
    if (state != null) {
      if (state.notificationMode == NotificationMode.silent) {
        return;
      }
      if (state.notificationMode == NotificationMode.vibrationOnly) {
        await NotificationService.triggerVibration();
        await stop();
        return;
      }
      await NotificationService.triggerVibration();
    }
    _queue.clear();
    await _playDirect(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
  }

  Future<void> playTatastha([AppState? state]) async {
    if (isPlayingTatastha) {
      await stop();
      return;
    }
    if (state != null) {
      if (state.notificationMode == NotificationMode.silent) {
        return;
      }
      if (state.notificationMode == NotificationMode.vibrationOnly) {
        await NotificationService.triggerVibration();
        await stop();
        return;
      }
      await NotificationService.triggerVibration();
    }
    _queue.clear();
    await _playDirect(ActiveAudio.tatastha, 'assets/audio/tatastha.mp3');
  }

  // Backward compatibility alias for taste
  Future<void> playTaste([AppState? state]) => playTatastha(state);

  /// Unified mindful chime played when reminders are resumed
  Future<void> playMindfulChime(AppState state) async {
    if (state.isEffectivelyPaused()) return;
    if (state.notificationMode == NotificationMode.silent) {
      await stop();
      return;
    }
    if (state.notificationMode == NotificationMode.vibrationOnly) {
      await NotificationService.triggerVibration();
      await stop();
      return;
    }

    await NotificationService.triggerVibration();
    _queue.clear();
    if (state.exhale.enabled && state.tatastha.enabled) {
      _queue.add(const _QueuedAudio(
        sound: ActiveAudio.tatastha,
        asset: 'assets/audio/tatastha.mp3',
      ));
      await _playDirect(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
    } else if (state.exhale.enabled) {
      await _playDirect(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
    } else if (state.tatastha.enabled) {
      await _playDirect(ActiveAudio.tatastha, 'assets/audio/tatastha.mp3');
    }
  }

  @override
  void dispose() {
    _queue.clear();
    _player.dispose();
    super.dispose();
  }
}

class _QueuedAudio {
  final ActiveAudio sound;
  final String asset;
  const _QueuedAudio({required this.sound, required this.asset});
}
