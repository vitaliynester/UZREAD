import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:reader_app/localization/demo_localization.dart';
import 'package:reader_app/models/downloaded_book_model.dart';
import 'package:reader_app/pages/about_book_page.dart';

import '../constants.dart';

class LastOpenedBookPage extends StatefulWidget {
  @override
  _LastOpenedBookPageState createState() => _LastOpenedBookPageState();
}

class _LastOpenedBookPageState extends State<LastOpenedBookPage> {
  Future<DownloadedBookModel> book;

  @override
  void initState() {
    book = readLastOpenedBook();
    super.initState();
  }

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
          title: Text(
            DemoLocalization.of(context).getTranslatedValue("last_opened_book"),
            style: TextStyle(color: textColor),
          ),
        ),
        backgroundColor: backgroudColor,
        body: FutureBuilder(
          future: book,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return AboutBookPage(
                book: snapshot.data,
              );
            } else {
              return Center(
                child: Text("NO LAST OPENED BOOK"),
              );
            }
          },
        ));
  }
}

Future<DownloadedBookModel> readLastOpenedBook() async {
  bool existJson = await checkFileExist(
      "last_opened_book.json", "/storage/emulated/0/Uzlib");
  if (existJson) {
    var jsonSourceData =
        await File("/storage/emulated/0/Uzlib/last_opened_book.json")
            .readAsString();
    DownloadedBookModel book =
        new DownloadedBookModel.fromJson(json.decode(jsonSourceData));
    return book;
  }
  return null;
}

Future<bool> checkFileExist(String fileName, String filePath) async {
  bool exist = await File("$filePath/$fileName").exists();
  return exist;
}
