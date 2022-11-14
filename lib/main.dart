import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'hmm.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'English to Hindi Translator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SpeechTranslator());
  }
}

class SpeechTranslator extends StatefulWidget {
  const SpeechTranslator({super.key});

  @override
  State<SpeechTranslator> createState() => _SpeechTranslatorState();
}

class _SpeechTranslatorState extends State<SpeechTranslator> {
  late stt.SpeechToText _speechHMM;
  bool _isListening = false;
  final TextEditingController _controllerEn = TextEditingController();
  final TextEditingController _controllerHi = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  var vocabSentences = [
    'hello',
    'hi',
    'hey',
    'thank you',
    'thanks',
    'cost',
    'price',
    'water',
    'drink',
    'food',
    'eat',
    'tourist place',
    'visit place',
    'direction',
    'way',
    'ride'
  ];
  var prevSnack = DateTime.now();

  @override
  void initState() {
    super.initState();
    _speechHMM = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: RichText(
              text: const TextSpan(children: [
            TextSpan(
              text: "English ",
              style: TextStyle(fontSize: 20),
            ),
            WidgetSpan(
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
            TextSpan(
              text: " Hindi Translate",
              style: TextStyle(fontSize: 20),
            )
          ])),
          centerTitle: true,
          backgroundColor: Colors.lightBlue[200],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
            height: 70,
            width: 70,
            child: FittedBox(
                child: FloatingActionButton(
              onPressed: _listen,
              child: _isListening
                  ? const DecoratedIcon(
                      Icons.mic,
                      shadows: [
                        BoxShadow(
                          blurRadius: 12.0,
                          color: Colors.deepPurpleAccent,
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.mic_none,
                    ),
            ))),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Row(children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(30, 30, 0, 10),
                  child: const Text(
                    "ENGLISH",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  height: 20,
                  child: IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => _speakEn(),
                  ),
                ),
              ]),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 30,
              height: 100,
              child: TextField(
                maxLines: null,
                controller: _controllerEn,
                onChanged: _entohi,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Try speaking "Hello"',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.fromLTRB(30, 0, 30, 0)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(30, 30, 0, 10),
                  child: const Text(
                    "HINDI",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  height: 20,
                  child: IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => _speakHi(),
                  ),
                ),
              ]),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 30,
              height: 100,
              child: TextField(
                controller: _controllerHi,
                onChanged: (value) {},
                decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.fromLTRB(30, 0, 30, 0)),
              ),
            ),
            Container(
                child: OutlinedButton(
              child: RichText(
                text: const TextSpan(
                  children: [
                    WidgetSpan(
                      child: Icon(Icons.warning, size: 14),
                    ),
                    TextSpan(
                      text: " Incorrect recongition?",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              onPressed: () => _correctLabel(context),
            )),
            const SizedBox(
              height: 200,
            ),
            SizedBox(
              width: 150,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _showVocab(context),
                child: const Text('Sentences list'),
              ),
            ),
          ],
        )));
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speechHMM.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechHMM.listen(
          onResult: (val) => setState(() {
            String en_text = val.recognizedWords;
            en_text = en_text.toLowerCase();
            if (vocabSentences.contains(en_text)) {
              _entohi(en_text);
              _controllerEn.text = en_text;
            } else {
              _controllerEn.text = '';
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechHMM.stop();
    }
  }

  void _entohi(String en_text) {
    String hi_text = '';
    if (en_text == 'hello' || en_text == 'hi' || en_text == 'hey') {
      hi_text = 'नमस्ते';
    } else if (en_text == 'thank you' || en_text == 'thanks') {
      hi_text = 'धन्यवाद';
    } else if (en_text == 'cost' || en_text == 'price') {
      hi_text = 'इसकी कीमत क्या हैं?';
    } else if (en_text == 'water' || en_text == 'drink') {
      hi_text = 'पानी किधर मिलेगा?';
    } else if (en_text == 'food' || en_text == 'eat') {
      hi_text = 'खाना किधर मिलेगा?';
    } else if (en_text == 'tourist place' || en_text == 'visit place') {
      hi_text = 'घूमने की जगह बताना आसपास';
    } else if (en_text == 'direction' || en_text == 'way') {
      hi_text = 'रास्ता बताना';
    } else if (en_text == 'ride') {
      hi_text = 'सवारी किधर मिलेगी?';
    } else {
      hi_text = '';
      final difference = DateTime.now().difference(prevSnack);
      if (difference.inSeconds > 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Try phrases from vocabulary'),
        ));
        prevSnack = DateTime.now();
      }
    }
    _controllerHi.text = hi_text;
  }

  Future<void> _showVocab(BuildContext context) {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding: const EdgeInsets.fromLTRB(100, 220, 100, 220),
            child: Stack(
              children: <Widget>[
                Container(
                  // width: 100,
                  // height: 100,
                  alignment: Alignment.center,
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Hello\nHi\nHey\nThank you\nThanks\nCost\nPrice\nWater\nDrink\nFood\nEat\nTourist place\nVisit place\nDirection\nWay\nRide',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0.0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.close,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<void> _correctLabel(BuildContext context) {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              child: SingleChildScrollView(
            child: Stack(children: [
              Column(
                children: <Widget>[
                  const SizedBox(
                    height: 50,
                    width: 250,
                  ),
                  const Text("Enter the word you spoke"),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      validator: _checkLabel,
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("SUBMIT")),
                ],
              ),
              Positioned(
                right: 0.0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ));
        });
  }

  String? _checkLabel(String? s) {
    if (s != null) {
      s = s.toLowerCase();
      if (vocabSentences.contains(s)) {
        return null;
      }
    }
    return 'Input word from vocabulary';
  }

  Future _speakEn() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(0.7);
    await flutterTts.setSpeechRate(0.5);

    String text = _controllerEn.text;
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future _speakHi() async {
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(0.7);
    await flutterTts.setSpeechRate(0.5);

    String text = _controllerHi.text;
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }
}
