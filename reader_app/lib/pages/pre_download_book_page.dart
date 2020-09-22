import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
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
  PreDownloadModel _bookToFile;
  DownloadedBookModel _downloadedBook;
  String _pathToBook;
  bool _existBook = false;
  DownloadStatus _status = null;
  String _buttonText = "";
  ReceivePort _receivePort = new ReceivePort();

  readyToDownload(AsyncSnapshot<dynamic> snapshot) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      setStateIfMounted(() {
        _status = DownloadStatus.loading;
        _buttonText =
            DemoLocalization.of(context).getTranslatedValue("downloading");
      });
      await downloadBook(snapshot.data.bookDownloadUrl, snapshot.data.bookImage,
          snapshot.data.bookName);
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
      Navigator.of(context).pop(MyException.NoInternet);
      return null;
    }

    try {
      var data = await http.get(url);
      var jsonData = json.decode(data.body);
      var book = new PreDownloadModel(
          jsonData["book_authors"],
          jsonData["book_description"],
          jsonData["book_download_url"],
          jsonData["book_image"],
          jsonData["book_name"]);
      var tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query:
              'SELECT * FROM task WHERE status=2 AND file_name = "${book.bookName.replaceAll(" ", "_")}.${widget.extension}"');
      _downloadedBook = createObjectAfterDownload(book);
      if (tasks.length > 0) {
        setStateIfMounted(() {
          _status = DownloadStatus.loading;
        });
      }
      bool existBook = await checkFileExist(
          "${book.bookName.replaceAll(" ", "_")}.${widget.extension}",
          "/storage/emulated/0/Uzread/books");
      if (existBook && tasks.length == 0) {
        setStateIfMounted(() {
          _status = DownloadStatus.readyToRead;
        });
      }
      setStateIfMounted(() {
        _bookToFile = book;
        _existBook = existBook;
        if (_status == null) {
          _status = DownloadStatus.readyToDownload;
        }
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
    _receivePort.listen((dynamic data) async {
      DownloadTaskStatus status = data[1];
      var name = await _book.then((value) =>
          "${value.bookName.replaceAll(" ", "_")}.${widget.extension}");

      if (status == DownloadTaskStatus(2)) {
        final tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query: 'SELECT * FROM task WHERE status=2 AND file_name = "$name"');
        if (tasks.length > 0) {
          setStateIfMounted(() {
            _status = DownloadStatus.loading;
            _buttonText =
                DemoLocalization.of(context).getTranslatedValue("downloading");
          });
        }
      }
      if (status == DownloadTaskStatus(3)) {
        final tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query: 'SELECT * FROM task WHERE status=3 AND file_name = "$name"');
        if (tasks.length > 0) {
          var downloadedBook = createObjectAfterDownload(_bookToFile);
          await writeToDownloadedList(downloadedBook);
          setStateIfMounted(() {
            _status = DownloadStatus.readyToRead;
            _existBook = true;
            _buttonText =
                DemoLocalization.of(context).getTranslatedValue("read");
          });
        }
      }
      if (data[2] > 0) {
        final tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query:
                'SELECT * FROM task WHERE status=2 AND file_name = "$name" AND progress=100');
        if (tasks.length > 0) {
          var downloadedBook = createObjectAfterDownload(_bookToFile);
          await writeToDownloadedList(downloadedBook);
          setStateIfMounted(() {
            _status = DownloadStatus.readyToRead;
            _existBook = true;
            _buttonText =
                DemoLocalization.of(context).getTranslatedValue("read");
          });
        }
      }
      if (status == DownloadTaskStatus(4)) {
        setStateIfMounted(() {
          _status = DownloadStatus.readyToDownload;
          _buttonText =
              DemoLocalization.of(context).getTranslatedValue("retry");
        });
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    super.initState();
  }

  @override
  Future<void> dispose() async {
    IsolateNameServer.removePortNameMapping("downloader_send_port");
    if (!_existBook) {
      if (_bookToFile != null) {
        await writeToDownloadedList(createObjectAfterDownload(_bookToFile));
      }
    }
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
        await new io.Directory("/storage/emulated/0/Uzread/images")
            .create(recursive: true);

    final myBookDir = await new io.Directory("/storage/emulated/0/Uzread/books")
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
    var downloadedBook = createObjectAfterDownload(_bookToFile);
    _downloadedBook = downloadedBook;
    await writeToDownloadedList(downloadedBook);
  }

  void buttonText() {
    setStateIfMounted(() {
      switch (_status) {
        case DownloadStatus.loading:
          setStateIfMounted(() {
            _buttonText =
                DemoLocalization.of(context).getTranslatedValue("downloading");
          });
          break;
        case DownloadStatus.readyToDownload:
          setStateIfMounted(() {
            _buttonText =
                "${DemoLocalization.of(context).getTranslatedValue("download")} (${widget.size})";
          });
          break;
        case DownloadStatus.readyToRead:
          setStateIfMounted(() {
            _buttonText =
                DemoLocalization.of(context).getTranslatedValue("read");
          });
          break;
      }
    });
  }

  Future<bool> checkBookExist(DownloadedBookModel checkedBook) async {
    var data = await io.File("/storage/emulated/0/Uzread/downloaded_books.json")
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
    String imagePath = "/storage/emulated/0/Uzread/images/$fileName.jpg";
    String bookPath =
        "/storage/emulated/0/Uzread/books/$fileName.${widget.extension}";
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
        "downloaded_books.json", "/storage/emulated/0/Uzread");

    if (existFile) {
      var data =
          await io.File("/storage/emulated/0/Uzread/downloaded_books.json")
              .readAsString();
      bool existBookInList = await checkBookExist(book);

      if (!existBookInList) {
        var list = getBooksFromFile(data);
        list.add(book);
        var file = io.File("/storage/emulated/0/Uzread/downloaded_books.json");
        await file.writeAsString(json.encode(list));
      }
    } else {
      var file = io.File("/storage/emulated/0/Uzread/downloaded_books.json");
      await file.writeAsString(json.encode(book.toJson()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DemoLocalization.of(context).getTranslatedValue("book_description"),
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
                        "${DemoLocalization.of(context).getTranslatedValue("book_authors")}: ${snapshot.data.bookAuthors}",
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
                              "${DemoLocalization.of(context).getTranslatedValue("description")}: ${snapshot.data.bookDescription}",
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
                            await OpenFile.open(_downloadedBook.bookPath);
                            await writeToFileLastReadedBook();
                            break;
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(7.2),
                        child: Text(
                          _buttonText,
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
      ),
    );
  }

  Future writeToFileLastReadedBook() async {
    var file = File("/storage/emulated/0/Uzread/last_opened_book.json");
    await file.writeAsString(json.encode(_downloadedBook.toJson()));
  }
}
