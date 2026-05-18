import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fcm_shared_isolate/fcm_shared_isolate.dart';
import 'package:flutter/services.dart';

late FcmSharedIsolate fcmSharedIsolate;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  fcmSharedIsolate = FcmSharedIsolate();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    future = getFcmToken();
  }

  Future<String?>? future;

  Future<String?> getFcmToken() async {
    String? token;
    try {
      /*
      / Make sure you have the google-service.json 
      / files in you android and or ios folder respectively
      */
      if (Platform.isIOS) {
        await fcmSharedIsolate.requestPermission();
      }
      token = await fcmSharedIsolate.getToken().timeout(Duration(seconds: 8));
    } on PlatformException catch (e, stackTrace) {
      debugPrint("Error: $e, $stackTrace");
      token = e.message ?? 'PlatformException happened';
      if (token.contains('FirebaseApp.initializeApp')) {
        token =
            'You have no google-service.json files in the respective folder (android or ios)';
      }
    } on TimeoutException catch (e, stackTrace) {
      debugPrint("Error: $e, $stackTrace");
      token = e.message ?? 'TimeoutException happened';
    } catch (e, stackTrace) {
      debugPrint("Error: $e, $stackTrace");
      token = e.toString();
      if (token.contains('FirebaseApp.initializeApp')) {
        token =
            'You have no google-service.json files in the respective folder (android or ios)';
      }
    }
    return token;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FCM Shared Isolate example app')),
        body: Center(
          child: Column(
            spacing: 8,
            children: [
              Text('Hello World'),
              FutureBuilder(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(snapshot.data ?? 'No token found'),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Loading Firebase Token ...'),
                        SizedBox(height: 8),
                        CircularProgressIndicator.adaptive(),
                      ],
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    future = getFcmToken();
                  });
                },
                label: Text('call getToken() again'),
                icon: Icon(Icons.restore),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
