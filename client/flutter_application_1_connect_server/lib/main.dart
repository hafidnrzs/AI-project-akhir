import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Classification',
      home: ImageUploader(),
    );
  }
}

class ImageUploader extends StatefulWidget {
  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _image;
  bool isUploading = false;
  String responseMessage = '';

  Future getImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (image != null) {
        _image = File(image.path);
        responseMessage = '';
      } else {
        print('No image selected.');
      }
    });
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

      final uri = Uri.parse("http://192.168.1.4:5000/upload");
      var request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        print('Image uploaded');
        String responseBody = await response.stream.bytesToString();
        setState(() {
          responseMessage = json.decode(responseBody);
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
        child: Column(
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
                    onClick: getImage,
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
                  Text(responseMessage),
                ],
              ),
            ),
          ],
        ),
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
