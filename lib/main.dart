// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';
import 'package:blocgdetutorial/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as devtools show log;

//Oluşan veri değişimlerini sergileyen bir test methodu
extension Log on Object {
  void log() => devtools.log(toString());
}

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
      //Bloc Entegre yolu temel seviye
      home: BlocProvider(
        create: (_) => PersonBloc(),
        child: const HomeScreen(),
      ),
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
//extension sonunda kullanılan on takısı ardından gelen Sınıf için geçerlidir
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

  @override
  String toString() => "Person(name: $name, age: $age)";
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
  String toString() =>
      "FetchResult (isRetrievedFromCache = $isRetrievedFromCache, persons = $persons)";
}

//Temel Bloc Tanımlaması (Event,State)
class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonBloc() : super(null) {
    //Bloc içinde event belirleme
    on<LoadPersonsAction>(
      (event, emit) async {
        //todo
        final url = event.url;
        if (_cache.containsKey(url)) {
          //Cache içinde bulunan veri
          final cachedPersons = _cache[url]!;
          final result = FetchResult(
            persons: cachedPersons,
            isRetrievedFromCache: true,
          );
          emit(result);
        } else {
          final persons = await getPersons(url.urlString);
          _cache[url] = persons;
          final result = FetchResult(
            persons: persons,
            isRetrievedFromCache: false,
          );
          emit(result);
        }
      },
    );
  }
}

//Iterable list sınıfının miras aldığı temeldir
extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  context.read<PersonBloc>().add(
                        const LoadPersonsAction(url: PersonUrl.persons1),
                      );
                },
                child: const Text("Load Persons1.json"),
              ),
              TextButton(
                onPressed: () {
                  context.read<PersonBloc>().add(
                        const LoadPersonsAction(url: PersonUrl.persons2),
                      );
                },
                child: const Text("Load Persons2.json"),
              ),
            ],
          ),
          BlocBuilder<PersonBloc, FetchResult?>(
            //Builder parametresinin çalışma şartını belirler
            buildWhen: (previous, current) {
              return previous?.persons != current?.persons;
            },
            builder: (context, state) {
              state?.log();
              final persons = state?.persons;
              if (persons == null) {
                return const SizedBox();
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index]!;
                    return ListTile(
                      title: Text(person.name),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
