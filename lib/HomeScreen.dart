import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:DesCon/RedrawScreen.dart';
import 'package:DesCon/RecognizerScreen.dart';
import 'package:DesCon/CreditsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ImagePicker _picker;
  List<CameraDescription>? _cams;
  CameraController? _ctrl;
  Future<void>? _initCtrl;
  int _idx = 0;
  bool _isLoading = true;
  String? _errorMessage;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    _initCams();
  }

  Future<void> _initCams() async {
    setState(() => _isLoading = true);
    try {
      _cams = await availableCameras();
      if (_cams == null || _cams!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
          _isLoading = false;
        });
        return;
      }
      await _startCam(_cams![_idx]);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startCam(CameraDescription cam) async {
    _ctrl?.dispose();
    _ctrl = CameraController(cam, ResolutionPreset.medium);
    _initCtrl = _ctrl!.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to start camera: $e';
          _isLoading = false;
        });
      }
    });
    await _initCtrl;
  }

  void _flipCam() async {
    if (_cams == null || _cams!.length < 2 || _isLoading) return;
    setState(() => _isLoading = true);
    _idx = (_idx + 1) % _cams!.length;
    await _startCam(_cams![_idx]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 80);
      if (xfile != null && mounted) {
        final file = File(xfile.path);
        if (file.existsSync()) {
          setState(() => _selectedImage = file);
          _navigateBasedOnAction(context, file);
        } else {
          _showSnackBar(context, 'Failed to load image');
        }
      }
    } catch (e) {
      _showSnackBar(context, 'Error picking image: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _snap(BuildContext context) async {
    if (_ctrl == null || !_ctrl!.value.isInitialized || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final xfile = await _ctrl!.takePicture();
      final file = File(xfile.path);
      if (file.existsSync() && mounted) {
        setState(() => _selectedImage = file);
        _navigateBasedOnAction(context, file);
      } else {
        _showSnackBar(context, 'Failed to capture image');
      }
    } catch (e) {
      _showSnackBar(context, 'Error capturing image: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateBasedOnAction(BuildContext context, File file) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Enhance Blueprint'),
              onTap: () => Navigator.pop(context, 'enhance'),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Recognize Text'),
              onTap: () => Navigator.pop(context, 'recognize'),
            ),
          ],
        ),
      ),
    );
    if (action == 'enhance') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RedrawScreen(originalImage: file)));
    } else if (action == 'recognize') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RecognizerScreen(file)));
    }
  }

  void _navigateToCredits(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreditsScreen()),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DesCon Hub', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _navigateToCredits(context),
            tooltip: 'Credits',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _CamView(
                ctrl: _ctrl,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
              ),
            ),
            _BotBar(
              onFlip: _flipCam,
              onSnap: () => _snap(context),
              onPick: _pick,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _CamView extends StatelessWidget {
  final CameraController? ctrl;
  final bool isLoading;
  final String? errorMessage;

  const _CamView({
    required this.ctrl,
    required this.isLoading,
    this.errorMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (ctrl == null || !ctrl!.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera unavailable',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CameraPreview(
        ctrl!,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _BotBar extends StatelessWidget {
  final VoidCallback onFlip;
  final VoidCallback onSnap;
  final Function(BuildContext, ImageSource) onPick;
  final bool isLoading;

  const _BotBar({
    required this.onFlip,
    required this.onSnap,
    required this.onPick,
    required this.isLoading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.grey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AnimatedIconButton(
              icon: Icons.rotate_left,
              tooltip: 'Flip camera',
              size: 35,
              onPressed: isLoading ? null : onFlip,
            ),
            _AnimatedIconButton(
              icon: Icons.camera,
              tooltip: 'Take picture',
              size: 50,
              onPressed: isLoading ? null : onSnap,
            ),
            _AnimatedIconButton(
              icon: Icons.image_outlined,
              tooltip: 'Pick from gallery',
              size: 35,
              onPressed: isLoading ? null : () => onPick(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onPressed;

  const _AnimatedIconButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: onPressed != null ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 200),
      child: IconButton(
        icon: Icon(icon, size: size, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
        disabledColor: Colors.grey,
        splashRadius: 24,
      ),
    );
  }
}