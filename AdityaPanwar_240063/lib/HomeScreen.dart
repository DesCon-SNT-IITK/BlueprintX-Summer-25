import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:BluePrintX/RedrawScreen.dart';
import 'package:BluePrintX/RecognizerScreen.dart';

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      if (mounted) {
        setState(() {});
      }
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
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 80);
      if (xfile != null && mounted) {
        final file = File(xfile.path);
        debugPrint('Picked image: ${file.path}, exists: ${file.existsSync()}');
        if (file.existsSync()) {
          setState(() => _selectedImage = file);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RedrawScreen(originalImage: file)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load image')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _snap(BuildContext context) async {
    if (_ctrl == null || !_ctrl!.value.isInitialized || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final xfile = await _ctrl!.takePicture();
      final file = File(xfile.path);
      debugPrint('Captured image: ${file.path}, exists: ${file.existsSync()}');
      if (file.existsSync() && mounted) {
        setState(() => _selectedImage = file);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RedrawScreen(originalImage: file)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(selectedImage: _selectedImage),
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
              semanticsLabel: 'Initializing camera',
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
              semanticsLabel: errorMessage,
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
          semanticsLabel: 'Camera unavailable',
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: constraints.maxWidth,
                child: CameraPreview(
                  ctrl!,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final File? selectedImage;

  const _TopBar({this.selectedImage, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _IconTxt(
              icon: Icons.scanner,
              txt: 'Scan',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan feature coming soon!')),
                );
              },
            ),
            _IconTxt(
              icon: Icons.document_scanner,
              txt: 'Recognizer',
              onTap: () {
                if (selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an image first')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecognizerScreen(selectedImage!),
                  ),
                );
              },
            ),
            _IconTxt(
              icon: Icons.assignment_sharp,
              txt: 'Enhance',
              onTap: () {
                if (selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an image first')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RedrawScreen(originalImage: selectedImage!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTxt extends StatelessWidget {
  final IconData icon;
  final String txt;
  final VoidCallback? onTap;

  const _IconTxt({required this.icon, required this.txt, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: Colors.white,
              semanticLabel: txt,
            ),
            const SizedBox(height: 4),
            Text(
              txt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              semanticsLabel: txt,
            ),
          ],
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
            colors: [Colors.blueAccent, Colors.deepPurple],
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