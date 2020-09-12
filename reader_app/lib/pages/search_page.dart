import 'package:flutter/material.dart';
import 'package:reader_app/components/search_field.dart';
import 'package:reader_app/localization/demo_localization.dart';
import 'package:reader_app/main.dart';
import 'package:reader_app/models/language.dart';

import '../constants.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: textColor,
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 50,
        leading: IconButton(
          icon: Icon(Icons.info),
          onPressed: () {
            showAboutDialog(
                context: context,
                applicationIcon: Image(
                  image: AssetImage("lib/assets/uzlib_png.png"),
                  height: 50,
                  width: 50,
                ),
                applicationName: "UZLIB",
                applicationLegalese: "© 2020 UZLIB",
                applicationVersion: '1.0',
                children: <Widget>[
                  Text(
                    DemoLocalization.of(context)
                        .getTranslatedValue("about_decription"),
                    textAlign: TextAlign.start,
                  ),
                ]);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: DropdownButton(
              underline: SizedBox(),
              icon: Icon(
                Icons.language,
                color: textColor,
              ),
              items: Language.languageList()
                  .map<DropdownMenuItem<Language>>((lang) => DropdownMenuItem(
                        value: lang,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Text(
                              lang.name,
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              lang.flag,
                              style: TextStyle(fontSize: 20),
                            )
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (Language language) {
                _changeLanguage(language);
              },
            ),
          ),
        ],
      ),
      backgroundColor: backgroudColor,
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height - 50,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                ),
                Container(
                  child: Image.asset("lib/assets/uzlib_png.png"),
                  height: MediaQuery.of(context).size.height * .56,
                ),
                SearchBookField(),
                SizedBox(
                  height: 20,
                ),
                Text(
                  DemoLocalization.of(context)
                      .getTranslatedValue("search_text"),
                  style: TextStyle(color: textColor, fontSize: 16),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeLanguage(Language language) {
    Locale _buf;
    switch (language.languageCode) {
      case 'en':
        _buf = Locale(language.languageCode, 'US');
        break;
      case 'uz':
        _buf = Locale(language.languageCode, 'UZ');
        break;
      case 'ru':
        _buf = Locale(language.languageCode, 'RU');
        break;
      default:
        _buf = Locale(language.languageCode, 'US');
        break;
    }
    MyApp.setLocale(context, _buf);
  }
}
