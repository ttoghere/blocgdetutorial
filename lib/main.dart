// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonsAction implements LoadAction {
  final PersonUrl url;
  const LoadPersonsAction({
    required this.url,
  }) : super();
}

enum PersonUrl {
  persons1,
  persons2,
}

//Hosting yokken LiveServer extension ile simule edilebilir
extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.persons1:
        return "http://127.0.0.1:5500/api/persons1.json";
      case PersonUrl.persons2:
        return "http://127.0.0.1:5500/api/persons2.json";
    }
  }
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
  });

  //Süslü parantez olmadan method açma yolu örneği
  Person.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        age = json["age"];
}

//Local host get request
Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url)) //Get request
    .then((value) => value.close()) //Response
    .then((value) => value.transform(utf8.decoder).join()) //Stream
    .then((value) => json.decode(value) as List<dynamic>) //List
    .then((value) => value.map((e) => Person.fromJson(e)) //Iterable of Persons
        );

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;
  const FetchResult({
    required this.persons,
    required this.isRetrievedFromCache,
  });

  @override
  String toString() {
    "FetchResult (isRetrievedFromCache = $isRetrievedFromCache, persons = $persons)";
    return super.toString();
  }
}

class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonBloc() : super(null);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final Bloc myBloc;
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
      ),
    );
  }
}
