import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Car Classification',
      home: ImageUploader(),
    );
  }
}

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _image;
  bool isUploading = false;
  bool getResult = false;
  String responseMessage = '';

  Future captureImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      setState(() {
        if (image != null) {
          _image = File(image.path);
          responseMessage = '';
        } else {
          print('No image selected.');
        }
      });
    } catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future getImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      setState(() {
        if (image != null) {
          _image = File(image.path);
          responseMessage = '';
        } else {
          print('No image selected.');
        }
      });
    } catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future uploadImage() async {
    try {
      if (_image == null) {
        print('No image selected.');
        return;
      }

      setState(() {
        isUploading = true;
      });

      final uri = Uri.parse("http://192.168.1.19:5000/upload");
      var request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        print('Image uploaded');
        String responseBody = await response.stream.bytesToString();
        setState(() {
          responseMessage = json.decode(responseBody);
          getResult = true;
        });
      } else {
        print('Image not uploaded');
      }
    } catch (error) {
      print('Error uploading image: $error');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  void resetImage() {
    setState(() {
      _image = null;
      responseMessage = '';
      isUploading = false;
      getResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Car Classification'),
        actions: [
          IconButton(
            onPressed: resetImage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                height: 300,
                child: Center(
                    child: _image != null
                        ? Image.file(
                            _image!,
                            fit: BoxFit.contain,
                          )
                        : const Text('Tidak ada gambar terpilih.')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    CustomButton(
                      title: 'Ambil Foto',
                      icon: Icons.camera_alt,
                      onClick: captureImage,
                    ),
                    CustomButton(
                      title: 'Pilih dari Galeri',
                      icon: Icons.photo,
                      onClick: getImage,
                    ),
                    const SizedBox(height: 24),
                    Visibility(
                        visible: _image != null && !isUploading,
                        child: CustomButton(
                          title: 'Upload Gambar',
                          icon: Icons.upload,
                          onClick: uploadImage,
                        )),
                    Visibility(
                      visible: isUploading,
                      child: const CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
          Visibility(
            visible: getResult,
            child: Positioned(
              bottom: 0,
              child: Container(
                height: 150,
                padding: EdgeInsets.only(top: 24),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    )),
                child: Column(
                  children: [
                    Text(
                      'Hasil klasifikasi',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Text(
                      responseMessage,
                      style: TextStyle(fontSize: 32.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClick;

  const CustomButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onClick,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Text(title),
        ],
      ),
    );
  }
}
