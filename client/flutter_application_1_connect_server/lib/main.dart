import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool isUploading = false;
  String responseMessage = '';

  Future getImage() async {
    final image = await ImagePicker().getImage(source: ImageSource.gallery);

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
    if (_image == null) {
      print('No image selected.');
      return;
    }

    setState(() {
      isUploading = true;
    });

    final uri = Uri.parse("http://192.168.154.194:5000/upload");
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      print('Image uploaded');
      String responseBody = await response.stream.bytesToString();
      setState(() {
        responseMessage = responseBody;
      });
    } else {
      print('Image not uploaded');
    }

    setState(() {
      isUploading = false;
    });
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
        title: Text('Flutter Image Upload'),
        actions: [
          IconButton(
            onPressed: resetImage,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.file(
                        _image!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : Text('No image selected.'),
            SizedBox(height: 16),
            Visibility(
              visible: _image != null && !isUploading,
              child: ElevatedButton(
                onPressed: uploadImage,
                child: Text('Upload Image'),
              ),
            ),
            Visibility(
              visible: isUploading,
              child: CircularProgressIndicator(),
            ),
            SizedBox(height: 16),
            Text(responseMessage),
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
