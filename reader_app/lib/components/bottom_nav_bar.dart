import 'package:flutter/material.dart';
import 'package:reader_app/pages/last_opened_book_page.dart';
import 'package:reader_app/pages/recently_downloaded_page.dart';
import 'package:reader_app/pages/search_page.dart';

import '../constants.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      labelColor: textColor.withOpacity(.9),
      unselectedLabelColor: iconColor,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: textColor.withOpacity(.9),
      tabs: [
        Tab(
          icon: Icon(Icons.search),
        ),
        Tab(
          icon: Icon(Icons.offline_pin),
        ),
        Tab(
          icon: Icon(Icons.filter_1),
        ),
      ],
    );
  }
}

List<Widget> tabList = [
  Container(
    child: SearchPage(),
  ),
  Container(
    child: RecentlyDownloadedPage(),
  ),
  Container(
    child: LastOpenedBookPage(),
  ),
];
