import 'package:flutter/material.dart';
import 'package:reader_app/pages/found_books_page.dart';

import '../constants.dart';

class SearchBookField extends StatefulWidget {
  const SearchBookField({
    Key key,
  }) : super(key: key);

  @override
  _SearchBookFieldState createState() => _SearchBookFieldState();
}

class _SearchBookFieldState extends State<SearchBookField> {
  TextEditingController _controller = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .6,
      child: TextFormField(
        controller: _controller,
        onEditingComplete: () async {
          if (_controller.text.length > 2) {
            bool error = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => new FoundBooksPage(
                  query: _controller.text,
                ),
              ),
            );
            if (error == true) {
              final snackBar = SnackBar(
                backgroundColor: textColor.withOpacity(.2),
                duration: Duration(seconds: 3),
                content: Text("Server error"),
              );
              Scaffold.of(context).showSnackBar(snackBar);
            }
          } else {
            Scaffold.of(context).showSnackBar(SnackBar(
                backgroundColor: textColor.withOpacity(.2),
                duration: Duration(seconds: 1),
                content: Text('Please enter more than 2 symbol')));
          }
        },
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          suffixIcon: Icon(
            Icons.search,
            color: textColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: textColor),
          ),
        ),
      ),
    );
  }
}
