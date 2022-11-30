import 'package:flutter/material.dart';
import 'dart:math' as math show Random;
import 'package:bloc/bloc.dart';

//String List
const names = ["Foo", "Bar", "Baz"];

//Extradan method oluşturma yolu
extension RandomElement<T> on Iterable<T> {
  T getRandomElement() => elementAt(math.Random().nextInt(length));
}

//Temel seviye cubit örneği
class NamesCubit extends Cubit<String?> {
  NamesCubit() : super(null);

  void pickRandomNames() => emit(names.getRandomElement());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final NamesCubit cubit;

  //Cubit Tanımlama yolu
  @override
  void initState() {
    super.initState();
    cubit = NamesCubit();
  }

  //Cubitlerin kullanım sonrası kapatılması gereklidir
  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bloc Start"),
      ),
      body: StreamBuilder<String?>(
        stream: cubit.stream,
        builder: (context, snapshot) {
          final button = TextButton(
              onPressed: () => cubit.pickRandomNames(),
              child: const Text("Pick A Name"));
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return button;
            case ConnectionState.waiting:
              return button;
            case ConnectionState.active:
              return Column(
                children: [
                  Text(snapshot.data ?? ""),
                  button,
                ],
              );
            case ConnectionState.done:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
