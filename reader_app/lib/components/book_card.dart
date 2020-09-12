import 'package:flutter/material.dart';
import 'package:reader_app/models/book_model.dart';

import '../constants.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String pdfSize;
  final String image;
  final BookModel bookModel;

  const BookCard({
    Key key,
    this.title,
    this.author,
    this.pdfSize,
    this.image,
    this.bookModel,
  }) : super(key: key);

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
                  bookModel.title,
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
                  bookModel.author,
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
              Container(
                width: size.width * .6,
                child: Text(
                  bookModel.size,
                  style: TextStyle(color: textColor, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          Container(
            height: 80,
            child: image != null
                ? Image.network(
                    image,
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
