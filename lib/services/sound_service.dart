import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  // ===== CLOUDINARY URLs =====
  static const String _notificationUrl =
      'https://res.cloudinary.com/zy9bpr85/video/upload/v1790327241/notification.mp3';

  static const String _messageUrl =
      'https://res.cloudinary.com/zy9bpr85/video/upload/v1790327248/u_jww7bj79ux-binary-code-interface-sound-effects-sci-fi-computer-ui-sounds-209403.mp3';

  // ⚠️ BADILISHA hii na URL halisi ya success.mp3
  static const String _successUrl =
      'https://res.cloudinary.com/zy9bpr85/video/upload/v1790327241/notification.mp3';

  // ===== PLAY NOTIFICATION =====
  static Future<void> playNotification() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_notificationUrl));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  // ===== PLAY MESSAGE =====
  static Future<void> playMessage() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_messageUrl));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  // ===== PLAY SUCCESS =====
  static Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_successUrl));
    } catch (e) {
      print('🔊 Sound error: $e');
    }
  }

  // ===== VIBRATE =====
  static Future<void> vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      print('📳 Vibration error: $e');
    }
  }

  // ===== WISHLIST LISTENER (like mpya) =====
  static int _lastWishlistCount = -1;
  static bool _isWishlistListening = false;

  static void startWishlistListener() {
    if (_isWishlistListening) return;
    _isWishlistListening = true;

    FirebaseFirestore.instance
        .collection('wishlists')
        .snapshots()
        .listen((snapshot) {
      final count = snapshot.docs.length;

      // First time — set baseline
      if (_lastWishlistCount == -1) {
        _lastWishlistCount = count;
        return;
      }

      // Like mpya imeongezwa
      if (count > _lastWishlistCount) {
        playNotification();
        vibrate();
      }
      _lastWishlistCount = count;
    });
  }

  // ===== PLAY BY TYPE =====
  static Future<void> playByType(String type) async {
    switch (type) {
      case 'booking':
      case 'order':
        await playSuccess();
        break;
      case 'review':
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