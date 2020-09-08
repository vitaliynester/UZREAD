import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:reader_app/constants.dart';
import 'package:reader_app/models/downloaded_book_model.dart';

class AboutBookPage extends StatefulWidget {
  final DownloadedBookModel book;

  const AboutBookPage({Key key, this.book}) : super(key: key);
  @override
  _AboutBookPageState createState() => _AboutBookPageState();
}

class _AboutBookPageState extends State<AboutBookPage> {
  Future<bool> checkFileExist(String fileName, String filePath) async {
    bool exist = await File("$filePath/$fileName").exists();
    return exist;
  }

  Future writeToFileLastReadedBook() async {
    var file = File("/storage/emulated/0/Uzlib/last_opened_book.json");
    await file.writeAsString(json.encode(widget.book.toJson()));
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
          widget.book.title,
          style: TextStyle(color: textColor),
        ),
      ),
      backgroundColor: backgroudColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                height: 300,
                child: widget.book.image != null
                    ? Image.file(File(widget.book.image))
                    : Image.asset('lib/assets/empty_book.png'),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  widget.book.title,
                  style: TextStyle(color: textColor, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  "Authors: ${widget.book.author}",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              widget.book.description != ""
                  ? Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        "Description: ${widget.book.description}",
                        style: TextStyle(color: textColor, fontSize: 24),
                        textAlign: TextAlign.justify,
                      ),
                    )
                  : Container(),
              SizedBox(
                height: 25,
              ),
              GestureDetector(
                onTap: () async {
                  await OpenFile.open(widget.book.bookPath);
                  await writeToFileLastReadedBook();
                },
                child: Container(
                  padding: EdgeInsets.all(7.2),
                  child: Text(
                    "Read",
                    style: TextStyle(color: backgroudColor, fontSize: 24),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.7),
                    border: Border.all(),
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
              )
            ],
          ),
        ),
      ),
    );
  }
}
