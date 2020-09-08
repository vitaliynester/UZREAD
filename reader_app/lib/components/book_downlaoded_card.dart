import 'dart:io';

import 'package:flutter/material.dart';
import 'package:reader_app/models/downloaded_book_model.dart';

import '../constants.dart';

class BookDownloadedCard extends StatelessWidget {
  final DownloadedBookModel book;

  const BookDownloadedCard({Key key, this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.all(5.0),
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: size.width * .6,
                child: Text(
                  book.title,
                  style: TextStyle(color: textColor, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Container(
                width: size.width * .6,
                child: Text(
                  book.author,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              SizedBox(
                height: 5,
              ),
            ],
          ),
          Container(
            height: 80,
            child: book.image != ""
                ? Image.file(
                    File(book.image),
                    fit: BoxFit.fill,
                  )
                : Image.asset(
                    'lib/assets/empty_book.png',
                    fit: BoxFit.fill,
                  ),
          ),
        ],
      ),
      decoration: BoxDecoration(
        border: Border.all(color: iconColor),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
