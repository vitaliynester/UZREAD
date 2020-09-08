import 'dart:convert';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reader_app/localization/demo_localization.dart';
import 'package:reader_app/models/downloaded_book_model.dart';
import 'package:reader_app/models/pre_download_model.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

enum DownloadStatus { readyToDownload, loading, readyToRead }

class PreDownloadBookPage extends StatefulWidget {
  final String url;
  final String size;
  final String extension;

  const PreDownloadBookPage({Key key, this.url, this.size, this.extension})
      : super(key: key);
  @override
  _PreDownloadBookPageState createState() => _PreDownloadBookPageState();
}

class _PreDownloadBookPageState extends State<PreDownloadBookPage> {
  Future<PreDownloadModel> _book;
  String _bookId;
  String _bookPath;
  bool _isLoading = true;
  bool _existBook = false;
  DownloadStatus _status;
  String _buttonText = "";
  int _countDownloads = 0;
  ReceivePort _receivePort = new ReceivePort();

  readyToDownload(AsyncSnapshot<dynamic> snapshot) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      setStateIfMounted(() {
        _status = DownloadStatus.loading;
        _buttonText = "Downloading...";
      });
      await downloadBook(snapshot.data.bookDownloadUrl, snapshot.data.bookImage,
          snapshot.data.bookName);
      var downloadedBook = createObjectAfterDownload(new PreDownloadModel(
          snapshot.data.bookAuthors,
          snapshot.data.bookDescription,
          snapshot.data.bookDownloadUrl,
          snapshot.data.bookImage,
          snapshot.data.bookName));
      await writeToDownloadedList(downloadedBook);
    }
  }

  Future<bool> check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  Future<PreDownloadModel> _getResponse() async {
    var url = "http://93.170.123.234:5000/book_url?book_url=${widget.url}";
    var avConnection = await check();
    if (avConnection == false) {
      Navigator.of(context).pop(true);
      return null;
    }

    try {
      var data = await http.get(url);
      setState(() {
        _isLoading = true;
      });
      var jsonData = json.decode(data.body);
      var book = new PreDownloadModel(
          jsonData["book_authors"],
          jsonData["book_description"],
          jsonData["book_download_url"],
          jsonData["book_image"],
          jsonData["book_name"]);
      bool existBook = await checkFileExist(
          "${book.bookName.replaceAll(" ", "_")}.${widget.extension}",
          "/storage/emulated/0/Uzlib/books");
      setStateIfMounted(() {
        _isLoading = false;
        _existBook = existBook;
        _existBook
            ? _status = DownloadStatus.readyToRead
            : _status = DownloadStatus.readyToDownload;

        buttonText();
      });
      return book;
    } catch (e) {
      return _getResponse();
    }
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  @override
  void initState() {
    _book = _getResponse();

    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, 'downloader_send_port');
    _receivePort.listen((dynamic data) {
      DownloadTaskStatus status = data[1];
      if (status == DownloadTaskStatus(3)) {
        _countDownloads++;
        print(_countDownloads);
        if (_countDownloads == 2) {
          _countDownloads = 0;
          setStateIfMounted(() {
            _status = DownloadStatus.readyToRead;
            _buttonText = "Read";
            _bookId = data[0];
          });
        }
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    super.initState();
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping("downloader_send_port");
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  Future downloadBook(String bookUrl, String imageUrl, String name) async {
    final fileName = name.replaceAll(" ", "_");
    final fileBookName = fileName + ".${widget.extension}";
    final fileImageName = fileName + ".jpg";
    final myImageDir =
        await new io.Directory("/storage/emulated/0/Uzlib/images")
            .create(recursive: true);

    final myBookDir = await new io.Directory("/storage/emulated/0/Uzlib/books")
        .create(recursive: true);

    await FlutterDownloader.enqueue(
      url: imageUrl,
      savedDir: myImageDir.path,
      fileName: fileImageName,
      showNotification: false,
      openFileFromNotification: false,
    );
    await FlutterDownloader.enqueue(
      url: bookUrl,
      savedDir: myBookDir.path,
      fileName: fileBookName,
      showNotification: true,
      openFileFromNotification: true,
    );
    setStateIfMounted(() {
      _bookPath = fileBookName;
    });
  }

  void buttonText() {
    setStateIfMounted(() {
      _existBook
          ? _status = DownloadStatus.readyToRead
          : _status = DownloadStatus.readyToDownload;
      switch (_status) {
        case DownloadStatus.loading:
          setStateIfMounted(() {
            _buttonText = "Downloading ...";
          });
          break;
        case DownloadStatus.readyToDownload:
          setStateIfMounted(() {
            _buttonText = "Download (${widget.size})";
          });
          break;
        case DownloadStatus.readyToRead:
          setStateIfMounted(() {
            _buttonText = "Read";
          });
          break;
      }
    });
  }

  Future<bool> checkBookExist(DownloadedBookModel checkedBook) async {
    var data = await io.File("/storage/emulated/0/Uzlib/downloaded_books.json")
        .readAsString();
    List<DownloadedBookModel> existsBooks = new List<DownloadedBookModel>();
    try {
      List<dynamic> jsonData = json.decode(data);
      for (var item in jsonData) {
        existsBooks.add(new DownloadedBookModel.fromJson(item));
      }
    } catch (e) {
      var jsonData = json.decode(data);
      existsBooks.add(new DownloadedBookModel.fromJson(jsonData));
    }
    for (var book in existsBooks) {
      if (book.title == checkedBook.title &&
          book.author == checkedBook.author &&
          book.description == checkedBook.description) {
        return true;
      }
    }
    return false;
  }

  Future<bool> checkFileExist(String fileName, String filePath) async {
    bool exist = await io.File("$filePath/$fileName").exists();
    if (exist) {
      setStateIfMounted(() {
        _bookPath = "$filePath/$fileName";
      });
    }
    return exist;
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

  DownloadedBookModel createObjectAfterDownload(
      PreDownloadModel downloadedBook) {
    String fileName = downloadedBook.bookName.replaceAll(" ", "_");
    String imagePath = "/storage/emulated/0/Uzlib/images/$fileName.jpg";
    String bookPath =
        "/storage/emulated/0/Uzlib/books/$fileName.${widget.extension}";
    DownloadedBookModel book = new DownloadedBookModel(
        bookPath,
        downloadedBook.bookName,
        downloadedBook.bookAuthors,
        imagePath,
        downloadedBook.bookDescription);
    return book;
  }

  Future writeToDownloadedList(DownloadedBookModel book) async {
    bool existFile = await checkFileExist(
        "downloaded_books.json", "/storage/emulated/0/Uzlib");

    if (existFile) {
      var data =
          await io.File("/storage/emulated/0/Uzlib/downloaded_books.json")
              .readAsString();
      bool existBookInList = await checkBookExist(book);

      if (!existBookInList) {
        var list = getBooksFromFile(data);
        list.add(book);
        var file = io.File("/storage/emulated/0/Uzlib/downloaded_books.json");
        await file.writeAsString(json.encode(list));
      }
    } else {
      var file = io.File("/storage/emulated/0/Uzlib/downloaded_books.json");
      await file.writeAsString(json.encode(book.toJson()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Book description",
            style: TextStyle(color: textColor),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: textColor,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder(
          future: _book,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        DemoLocalization.of(context)
                            .getTranslatedValue("details_title"),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 300,
                        child: snapshot.data.bookImage != null
                            ? Image.network(snapshot.data.bookImage)
                            : Image.asset('lib/assets/empty_book.png'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(
                          snapshot.data.bookName,
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
                          "Authors: ${snapshot.data.bookAuthors}",
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
                      snapshot.data.bookDescription != ""
                          ? Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Text(
                                "Description: ${snapshot.data.bookDescription}",
                                style:
                                    TextStyle(color: textColor, fontSize: 24),
                                textAlign: TextAlign.justify,
                              ),
                            )
                          : Container(),
                      SizedBox(
                        height: 25,
                      ),
                      GestureDetector(
                        onTap: () async {
                          switch (_status) {
                            case DownloadStatus.readyToDownload:
                              setStateIfMounted(() {
                                _status = DownloadStatus.loading;
                              });
                              await readyToDownload(snapshot);
                              return;
                            case DownloadStatus.loading:
                              Scaffold.of(context).showSnackBar(
                                new SnackBar(
                                  content: Text(
                                    "Error! Book already downloading!",
                                  ),
                                  backgroundColor: textColor.withOpacity(.2),
                                ),
                              );
                              break;
                            case DownloadStatus.readyToRead:
                              if (_bookId == null) {
                                await OpenFile.open(_bookPath);
                              } else {
                                FlutterDownloader.open(taskId: _bookId);
                              }

                              break;
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(7.2),
                          child: Text(
                            "$_buttonText",
                            style:
                                TextStyle(color: backgroudColor, fontSize: 24),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.7),
                            border: Border.all(),
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                      )
                    ],
                  ),
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ));
  }
}
