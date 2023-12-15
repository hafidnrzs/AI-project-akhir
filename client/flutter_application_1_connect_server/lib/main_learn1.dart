import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Image Upload',
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

  Future getImage() async {
    final image = await ImagePicker().getImage(source: ImageSource.gallery);

    setState(() {
      if (image != null) {
        _image = File(image.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadImage() async {
    if (_image == null) {
      print('No image selected.');
      return;
    }

    final uri = Uri.parse("http://10.8.0.8:5000/upload");
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      print('Image uploaded');
    } else {
      print('Image not uploaded');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Image Upload'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!)
                : Text('No image selected.'),
            SizedBox(height: 16),
            Visibility(
              visible: _image != null,  // Tombol akan tampak hanya jika gambar sudah dipilih
              child: ElevatedButton(
                onPressed: uploadImage,
                child: Text('Upload Image'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
