import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_detection/hand_detection.dart';

class HandDetectorView extends StatefulWidget {
  final void Function(List<Hand> hands) onHandsDetected;

  const HandDetectorView({super.key, required this.onHandsDetected});

  @override
  State<HandDetectorView> createState() => _HandDetectorViewState();
}

class _HandDetectorViewState extends State<HandDetectorView>
    with AutomaticKeepAliveClientMixin {
  CameraController? _cameraController;
  late final HandDetector _detector;
  bool _isBusy = false;
  bool _isInitialized = false;
  List<CameraDescription> _cameras = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // mode: boxesAndLandmarks ni default — inarudisha bounding box + landmarks 21 + handedness
    _detector = HandDetector();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Chagua kamera ya mbele (front camera)
    final frontCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium, // 480p — inatosha kwa utambuzi wa mkono
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();

    if (!mounted) return;
    _cameraController!.lockCaptureOrientation();

    // Anzisha HandDetector kwenye background isolate (haifungii UI)
    // mode ya default ni HandMode.boxesAndLandmarks
    await _detector.initialize();

    if (!mounted) return;

    setState(() => _isInitialized = true);
    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    // Zuia kufanya kazi kwenye fremu nyingi kwa wakati mmoja
    if (_isBusy || !_isInitialized) return;
    _isBusy = true;

    try {
      // Hesabu kwa nguvu mwelekeo sahihi wa fremu
      final rotation = rotationForFrame(
        width: image.width,
        height: image.height,
        sensorOrientation: _cameraController!.description.sensorOrientation,
        isFrontCamera: _cameraController!.description.lensDirection == CameraLensDirection.front,
        deviceOrientation: _cameraController!.value.deviceOrientation,
      );

      final hands = await _detector.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: 320,
      );

      if (mounted) {
        // We check if hands is empty to avoid unnecessary parent rebuilds
        // if the parent logic doesn't need to know about "no hands" every frame
        // but usually, we pass it and handle throttling in the parent.
        widget.onHandsDetected(hands);
      }
    } catch (e) {
      debugPrint('Hand detection error: $e');
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    // Funga rasilimali hapa wakati widget inafutwa kabisa.
    // Kwa kutumia AutomaticKeepAliveClientMixin, hii itaitwa tu
    // wakati screen inatolewa kabisa kwenye navigation stack.
    if (_cameraController?.value.isStreamingImages ?? false) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // LAZIMA kwa AutomaticKeepAliveClientMixin
    if (!_isInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController!);
  }
}