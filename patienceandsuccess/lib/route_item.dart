import 'package:flutter/cupertino.dart';

typedef void RouteCallback(BuildContext context);

class RouteItem {
  RouteItem({
    @required this.title,
    @required this.subtitle,
    @required this.push,
  });

  final String title;
  final String subtitle;
  final RouteCallback push;
}
