import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:reader_app/components/book_card.dart';
import 'package:reader_app/constants.dart';
import 'package:reader_app/models/book_model.dart';
import 'package:reader_app/models/pre_download_model.dart';
import 'package:reader_app/models/search_model.dart';
import 'package:http/http.dart' as http;
import 'package:reader_app/pages/pre_download_book_page.dart';

class FoundBooksPage extends StatefulWidget {
  final String query;

  const FoundBooksPage({Key key, this.query}) : super(key: key);
  @override
  _FoundBooksPageState createState() => _FoundBooksPageState();
}

class _FoundBooksPageState extends State<FoundBooksPage> {
  bool _isLoading = false;
  int _countTotalPages = -1;
  int _currentPage = 1;
  ScrollController _scrollController = ScrollController();
  List<SearchModel> _smResponse = new List<SearchModel>();
  List<String> _listImages = new List<String>();
  Future<List<SearchModel>> _listFuture;

  @override
  void initState() {
    super.initState();
    _listFuture = _getResponse();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _currentPage != _countTotalPages &&
          _isLoading == false) {
        _listFuture = _getMoreData();
      }
    });
  }

  Future getBookInformation(SearchModel book) async {
    var url = "http://93.170.123.234:5000/book_url?book_url=${book.url}";
    var avConnection = await check();
    if (avConnection == false) {
      Navigator.of(context).pop(true);
      return null;
    }
    var data = await http.get(url);
    PreDownloadModel infoBook =
        new PreDownloadModel.fromJson(json.decode(data.body));
    setState(() {
      _listImages.add(infoBook.bookImage);
    });
  }

  Future<List<SearchModel>> _getMoreData() async {
    var avConnection = await check();
    if (avConnection == false) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(true);
    }
    List<SearchModel> nextPagesBook = List<SearchModel>();
    _currentPage += 1;
    if (_currentPage > _countTotalPages) {
      return null;
    }
    var url =
        "http://93.170.123.234:5000/book?book_name=${widget.query}&book_page=$_currentPage";
    print(url);
    try {
      setState(() {
        _isLoading = true;
      });
      var data = await http.get(url, headers: {"Connection": "keep-alive"});
      var jsonData = json.decode(data.body);
      for (var item in jsonData) {
        if (_countTotalPages < 0) {
          _currentPage = 1;
          _countTotalPages = item["total_page"];
        } else {
          SearchModel sm = new SearchModel(
              item["authors"],
              item["extension"],
              item["pages_count"],
              item["title"],
              item["total_size"],
              item["url"],
              item["year"]);
          nextPagesBook.add(sm);
        }
      }
      nextPagesBook
          .removeWhere((item) => item.url == null || item.title == null);
      for (var book in nextPagesBook) {
        await getBookInformation(book);
      }
      setState(() {
        _isLoading = false;
        _smResponse.addAll(nextPagesBook);
      });
      return _smResponse;
    } catch (e) {
      if (_countTotalPages > 0) {
        _currentPage -= 1;
        return _getMoreData();
      }
      Navigator.of(context).pop(true);
    }
  }

  Future<List<SearchModel>> _getResponse() async {
    var url = "http://93.170.123.234:5000/book?book_name=${widget.query}";
    var avConnection = await check();
    if (avConnection == false) {
      Navigator.of(context).pop(true);
      return null;
    }
    if (_smResponse.length != 0) {
      return _getMoreData().then((value) => value);
    } else {
      try {
        var data = await http.get(url);
        setState(() {
          _isLoading = true;
        });
        var jsonData = json.decode(data.body);
        try {
          if (jsonData["msg"] != "") {
            Navigator.of(context).pop(true);
            return null;
          }
        } catch (e) {}
        List<SearchModel> response = new List<SearchModel>();
        for (var item in jsonData) {
          if (_countTotalPages < 0) {
            _countTotalPages = item["total_page"];
          } else {
            SearchModel sm = new SearchModel(
                item["authors"],
                item["extension"],
                item["pages_count"],
                item["title"],
                item["total_size"],
                item["url"],
                item["year"]);
            response.add(sm);
            await getBookInformation(sm);
          }
        }
        response.removeWhere((item) => item.url == null || item.title == null);
        _smResponse = response;
        setState(() {
          _isLoading = false;
        });
        return _smResponse;
      } catch (e) {
        return _getResponse();
      }
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
          widget.query,
          style: TextStyle(color: textColor),
        ),
      ),
      body: Container(
        child: FutureBuilder(
          future: _listFuture,
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              controller: _scrollController,
              itemCount: snapshot.data.length + 1,
              itemBuilder: (context, index) {
                try {
                  if (index == _smResponse.length &&
                      _currentPage != _countTotalPages) {
                    return Center(child: CircularProgressIndicator());
                  } else if (_currentPage <= _countTotalPages) {
                    String img;
                    try {
                      img = _listImages[index];
                    } catch (e) {
                      img = null;
                    }
                    var book = new BookModel(
                        snapshot.data[index].title,
                        snapshot.data[index].authors,
                        snapshot.data[index].totalSize,
                        img,
                        snapshot.data[index].title);
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                new PreDownloadBookPage(
                              url: snapshot.data[index].url,
                              size: snapshot.data[index].totalSize,
                              extension: snapshot.data[index].extension,
                            ),
                          ),
                        );
                      },
                      child: BookCard(bookModel: book),
                    );
                  }
                } catch (e) {
                  return Card();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
