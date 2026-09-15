import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playNotification() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  static Future<void> playMessage() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/message.mp3'));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  static Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  static Future<void> vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      print('📳 Vibration error: $e');
    }
  }

  static Future<void> playByType(String type) async {
    switch (type) {
      case 'booking':
      case 'order':
        await playSuccess();
        break;
      case 'review':                       // ⭐ Review
      case 'chat':
      case 'message':
        await playMessage();
        break;
      default:
        await playNotification();
    }
    await vibrate();
  }
}