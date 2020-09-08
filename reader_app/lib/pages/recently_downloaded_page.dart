import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:reader_app/components/book_downlaoded_card.dart';
import 'package:reader_app/constants.dart';
import 'package:reader_app/localization/demo_localization.dart';
import 'package:reader_app/models/downloaded_book_model.dart';
import 'package:reader_app/pages/about_book_page.dart';

class RecentlyDownloadedPage extends StatefulWidget {
  @override
  _RecentlyDownloadedPageState createState() => _RecentlyDownloadedPageState();
}

class _RecentlyDownloadedPageState extends State<RecentlyDownloadedPage> {
  Future<List<DownloadedBookModel>> _downloadedBooks;

  @override
  void initState() {
    super.initState();
    _downloadedBooks = getDownloadedBook();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroudColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          title: Text(
            DemoLocalization.of(context)
                .getTranslatedValue("recently_downloaded_title"),
            style: TextStyle(
              color: textColor,
            ),
          ),
        ),
        body: FutureBuilder(
          future: _downloadedBooks,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data.length > 0) {
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (BuildContext context) =>
                                new AboutBookPage(
                              book: snapshot.data[index],
                            ),
                          ),
                        );
                      },
                      child: BookDownloadedCard(
                        book: snapshot.data[index],
                      ),
                    );
                  },
                );
              } else {
                return Text("NO DATA");
              }
            } else {
              return Center(
                child: Text(
                  "NO DOWNLOADED BOOKS",
                ),
              );
            }
          },
        ));
  }
}

List<DownloadedBookModel> getBooksFromFile(String jsonSourceData) {
  List<DownloadedBookModel> books = new List<DownloadedBookModel>();
  try {
    List<dynamic> jsonData = json.decode(jsonSourceData);
    for (var item in jsonData) {
      books.add(new DownloadedBookModel.fromJson(item));
    }
  } catch (e) {
    var jsonData = json.decode(jsonSourceData);
    books.add(new DownloadedBookModel.fromJson(jsonData));
  }
  return books;
}

Future<bool> checkFileExist(String fileName, String filePath) async {
  bool exist = await io.File("$filePath/$fileName").exists();
  return exist;
}

Future<bool> checkBookFileExist(String bookPath) async {
  bool exist = await io.File(bookPath).exists();
  return exist;
}

Future<List<DownloadedBookModel>> removeDeletedBooks() async {
  bool existJson = await checkFileExist(
      "downloaded_books.json", "/storage/emulated/0/Uzlib");
  if (existJson) {
    List<DownloadedBookModel> existingBooks = new List<DownloadedBookModel>();
    var jsonSourceData =
        await io.File("/storage/emulated/0/Uzlib/downloaded_books.json")
            .readAsString();
    var allBooks = getBooksFromFile(jsonSourceData);
    for (var book in allBooks) {
      if (await checkBookFileExist(book.bookPath)) {
        existingBooks.add(book);
      }
    }
    return existingBooks;
  }
  return null;
}

Future<List<DownloadedBookModel>> getDownloadedBook() async {
  List<DownloadedBookModel> books = await removeDeletedBooks();
  return books;
}
