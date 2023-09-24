import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'Drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _reporterNameController = TextEditingController();
  final TextEditingController _reporterNumberController =
      TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reportersLocationController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void deactivate() {
    // TODO: implement deactivate
    _reporterNameController.dispose();
    _reporterNumberController.dispose();
    _messageController.dispose();
    _reportersLocationController.dispose();
    super.deactivate();
  }
  // final TextEditingController _againPasswordController =
  //     TextEditingController();

  final picker = ImagePicker();
  File? _pickFile;

  VideoPlayerController? _controller;
  bool _isVideo = false;
  Position? currentPosition;
  bool _loadLocation = false;
  bool _loadingData = false;

  String myLocation = "";
  late String lat;
  late String long;

  String fileUrl = "";

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _loadLocation = true;
    });

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemark =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemark[0];

      setState(() {
        currentPosition = position;
        myLocation = " ${place.country} ${place.subAdministrativeArea}";
        // print("LLLLLLMMMMMMM ${place}");
      });
    } catch (e) {
      print(e);
    }

    setState(() {
      _loadLocation = false;
    });
    return position;

    // return await Geolocator.getCurrentPosition(
    //   desiredAccuracy: LocationAccuracy.high
    // );
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller!.dispose();

    super.dispose();
  }

  Future pickerImageGallery() async {
    try {
      XFile? image;
      image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        return;
      }

      final imageTemp = File(image.path);
      setState(() {
        _pickFile = imageTemp;
      });
    } catch (e) {
      print("+++++++++++++****${e} ++++++++++++");
    }
  }

  Future pickerImageCamera() async {
    try {
      XFile? image;
      image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        return;
      }

      final imageTemp = File(image.path);
      setState(() {
        _pickFile = imageTemp;
      });
    } catch (e) {
      print("+++++++++++++****${e} ++++++++++++");
    }
  }

  Future pickerVideoCamera() async {
    try {
      XFile? galleryVideo;

      galleryVideo = await picker.pickVideo(source: ImageSource.camera);

      if (galleryVideo == null) {
        return;
      }

      final imageTemp = File(galleryVideo.path);
      setState(() {
        _pickFile = imageTemp;
        _isVideo = true;
      });

      _controller = VideoPlayerController.file(_pickFile!);

      // Initialize the controller and store the Future for later use.
      _controller!.initialize();

      // Use the controller to loop the video.
      _controller!.setLooping(true);

      _controller!.play();
    } catch (e) {
      print("+++++++++++++****${e} ++++++++++++");
    }
  }

  Future pickerVideoGallery() async {
    try {
      XFile? galleryVideo;

      galleryVideo = await picker.pickVideo(source: ImageSource.gallery);

      if (galleryVideo == null) {
        return;
      }

      final imageTemp = File(galleryVideo.path);
      setState(() {
        _pickFile = imageTemp;
        _isVideo = true;
      });

      _controller = VideoPlayerController.file(_pickFile!);

      // Initialize the controller and store the Future for later use.
      _controller!.initialize();

      // Use the controller to loop the video.
      _controller!.setLooping(true);

      _controller!.play();
    } catch (e) {
      print("+++++++++++++****${e} ++++++++++++");
    }
  }

  Future<void> _launchUrl() async {
    final Uri _url = Uri(scheme: 'tel', path: "0280000000");
    if (await canLaunchUrl(_url)) {
      await launchUrl(_url);
    } else {
      throw Exception('Could not launch $_url');
    }
  }

  upLoadDataToDatabase() async {
    if (!_formKey.currentState!.validate()) return;

    print('bbbbbbbbb ${currentPosition?.latitude.toString()}');

    final lat = '${currentPosition?.latitude.toString()}';
    final long = '${currentPosition?.longitude.toString()}';

    String reporterName = _reporterNameController.value.text.trim();
    String reporterNumber = _reporterNumberController.value.text.trim();
    String message = _messageController.value.text.trim();
    String reportersLocation = _reportersLocationController.value.text.trim();

    setState(() {
      _loadingData = true;
    });

    String uniqueFileName = DateTime.now().microsecondsSinceEpoch.toString();
    // File path
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirToFile = referenceRoot.child("messageFiles");

    // the real file to storage
    Reference referenceFileToUpload = referenceDirToFile.child(uniqueFileName);
    try {
      await referenceFileToUpload.putFile(_pickFile!);

      fileUrl = await referenceFileToUpload.getDownloadURL();

      uploadReportToDatabase(
        fileSend: fileUrl,
        locationLat: lat,
        locationLong: long,
        messageReported: message,
        reporterLocation: reportersLocation,
        reporterName: reporterName,
        reporterPhone: reporterNumber,
      );
      Fluttertoast.showToast(
          msg: "Report Sent Successfully ",
          // msg: "${e.toString().replaceRange(0, 14, '').split(']')[1]}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Please check Your internet connection ",
          // msg: "${e.toString().replaceRange(0, 14, '').split(']')[1]}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }

    setState(() {
      _loadingData = false;
      _pickFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white, size: 30.0),
            onPressed: () {
              _launchUrl();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 30.0),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("/login_page/", (route) => false);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: MyDrawer(),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 8,
              ),
              Container(
                height: 250,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 8),
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                      image: AssetImage('assets/cctv.jpg'), fit: BoxFit.fill),
                ),
                child: _isVideo
                    ? VideoPlayer(_controller!)
                    : _pickFile == null
                        // child: _isVideo ? VideoPlayer(_controller!) : _pickFile == null
                        ? const Text("")
                        : Image.file(
                            _pickFile!,
                            fit: BoxFit.fill,
                          ),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 25,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 10.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Image',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Picker Image '),
                        content: const Text(
                            'picker Image from the Camera or Gallery'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: const Text('Cancel'),
                            // child: Icon(Icons.access_alarm),
                          ),
                          TextButton(
                            onPressed: () {
                              pickerImageGallery();
                              Navigator.pop(context, 'Good');
                              setState(() {
                                // source = source;
                                _pickFile = null;
                              });
                            },
                            child: const Icon(Icons.image),
                          ),
                          TextButton(
                            onPressed: () {
                              pickerImageCamera();
                              Navigator.pop(context, 'Good');
                              setState(() {
                                _pickFile = null;
                              });
                            },
                            child: const Icon(Icons.camera),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 10.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Video',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Picker Video '),
                        content: const Text(
                            'picker Video from the Camera or Gallery'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: const Text('Cancel'),
                            // child: Icon(Icons.access_alarm),
                          ),
                          TextButton(
                            onPressed: () {
                              pickerVideoGallery();
                              Navigator.pop(context, 'Good');
                              setState(() {
                                _pickFile = null;
                              });
                            },
                            child: const Icon(Icons.image),
                          ),
                          TextButton(
                            onPressed: () {
                              pickerVideoCamera();
                              Navigator.pop(context, 'Good');
                              setState(() {
                                _pickFile = null;
                              });
                            },
                            child: const Icon(Icons.video_call),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        controller: _reporterNameController,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 6) {
                            return "Please your name is too short ";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Reporters Name "),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 10) {
                            return "Report too short";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Please Type Your Report (Message) Here"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        controller: _reporterNumberController,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length <= 9) {
                            return "Please check Your phone number ";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Phone Number needed",
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        controller: _reportersLocationController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Where Do You Stay";
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Where Do You Stay",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // currentPosition != null ?  Text("${currentPosition.toString()}") : Text(""),
              const SizedBox(
                height: 8,
              ),
              Text(
                myLocation,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(
                height: 8,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 10.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.0)),
                  foregroundColor: Colors.white,
                ),
                child: _loadLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Get My Current Location For Easy Report',
                        style: TextStyle(fontSize: 15.0),
                      ),
                onPressed: () {
                  _determinePosition();

                  // print('bbbbbbbbb ${currentPosition?.latitude.toString()}');
                  _determinePosition().then((value) {
                    lat = '${value.latitude}';
                    long = '${value.longitude}';

                    print("lat: $lat, long:$long");
                  });
                },
              ),
              _loadLocation
                  ? Container()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 10.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0)),
                        foregroundColor: Colors.white,
                      ),
                      child: _loadingData
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send',
                              style: TextStyle(fontSize: 20.0),
                            ),
                      onPressed: () {
                        upLoadDataToDatabase();
                      },
                    ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> uploadReportToDatabase({
  required String reporterName,
  required String reporterPhone,
  required String reporterLocation,
  required String messageReported,
  required String fileSend,
  required String locationLat,
  required String locationLong,
}) async {
  CollectionReference users = FirebaseFirestore.instance.collection('report');
  FirebaseAuth auth = FirebaseAuth.instance;
  String? uid = auth.currentUser?.uid.toString();
  users.add({
    'reporterName': reporterName,
    'reporterPhone': reporterPhone,
    'reporterLocation': reporterLocation,
    'uid': uid,
    'messageReported': messageReported,
    "LocationLat": locationLat,
    "LocationLong": locationLong,
    "fileSend": fileSend,
    'timestamp': FieldValue.serverTimestamp()
  });
  return;
}
