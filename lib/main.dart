import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:decorated_icon/decorated_icon.dart';

void main() {
  runApp(MyApp());
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
        home: SpeechTranslator());
  }
}

class SpeechTranslator extends StatefulWidget {
  const SpeechTranslator({super.key});

  @override
  State<SpeechTranslator> createState() => _SpeechTranslatorState();
}

class _SpeechTranslatorState extends State<SpeechTranslator> {
  late stt.SpeechToText _speech;
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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: RichText(
              text: TextSpan(children: [
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
                  ? DecoratedIcon(
                      Icons.mic,
                      shadows: [
                        BoxShadow(
                          blurRadius: 12.0,
                          color: Colors.deepPurpleAccent,
                        ),
                      ],
                    )
                  : Icon(
                      Icons.mic_none,
                    ),
            ))),
        body: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Row(children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(30, 30, 0, 10),
                  child: Text(
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
                    icon: Icon(Icons.volume_up),
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
                    contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(30, 30, 0, 10),
                  child: Text(
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
                    icon: Icon(Icons.volume_up),
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
                    contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0)),
              ),
            ),
            SizedBox(
              width: 150,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _showVocab(context),
                child: Text('Sentences list'),
              ),
            ),
          ],
        ));
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            String text = val.recognizedWords;
            _controllerEn.text = text;
            text = text.toLowerCase();
            if (vocabSentences.contains(text)) {
              _entohi(text);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Try phrases from vocabulary'),
      ));
    }
    _controllerHi.text = hi_text;
  }

  Future<void> _showVocab(BuildContext context) {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding: EdgeInsets.fromLTRB(100, 220, 100, 220),
            child: Stack(
              children: <Widget>[
                Container(
                  // width: 100,
                  // height: 100,
                  alignment: Alignment.center,
                  child: Align(
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
                    child: Align(
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
