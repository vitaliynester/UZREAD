import 'package:flutter/material.dart';
import 'package:reader_app/localization/demo_localization.dart';
import 'package:reader_app/pages/found_books_page.dart';

import '../constants.dart';

class SearchBookField extends StatefulWidget {
  @override
  _SearchBookFieldState createState() => _SearchBookFieldState();
}

class _SearchBookFieldState extends State<SearchBookField> {
  TextEditingController _controller = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .6,
      child: Theme(
        data: ThemeData(
          primaryColor: textColor,
        ),
        child: TextFormField(
          controller: _controller,
          onEditingComplete: () async {
            await searchFunction();
          },
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            suffixIcon: GestureDetector(
              onTap: () async {
                await searchFunction();
              },
              child: Icon(
                Icons.search,
                color: textColor,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  Future searchFunction() async {
    if (_controller.text.length > 2) {
      var query = _controller.text;
      _controller.clear();
      var error = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => new FoundBooksPage(
            query: query,
          ),
        ),
      );
      if (error == MyException.NoInternet) {
        final snackBar = SnackBar(
          backgroundColor: textColor.withOpacity(.2),
          duration: Duration(seconds: 3),
          content: Text(
            DemoLocalization.of(context).getTranslatedValue("no_internet"),
          ),
        );
        Scaffold.of(context).showSnackBar(snackBar);
      }
      if (error == MyException.NoResult ||
          error == MyException.ServerException) {
        final snackBar = SnackBar(
          backgroundColor: textColor.withOpacity(.2),
          duration: Duration(seconds: 3),
          content: Text(
            DemoLocalization.of(context)
                .getTranslatedValue("server_connection"),
          ),
        );
        Scaffold.of(context).showSnackBar(snackBar);
      }
    } else {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          backgroundColor: textColor.withOpacity(.2),
          duration: Duration(seconds: 1),
          content: Text(
            DemoLocalization.of(context)
                .getTranslatedValue("less_than_needed_query"),
          ),
        ),
      );
    }
  }
}
