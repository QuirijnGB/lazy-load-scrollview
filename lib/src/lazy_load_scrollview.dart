library lazy_load_scrollview;

import 'package:flutter/widgets.dart';

enum LoadingStatus { LOADING, STABLE }

typedef void EndOfPageListener();

class LazyLoadScrollView extends StatefulWidget {
  final ScrollView child;

  final EndOfPageListener endOfPageListener;

  final int scrollOffset;

  @override
  State<StatefulWidget> createState() => LazyLoadScrollViewState();

  LazyLoadScrollView({
    Key key,
    @required this.child,
    @required this.endOfPageListener,
    this.scrollOffset = 100,
  })  : assert(endOfPageListener != null),
        assert(child != null),
        super(key: key);
}

class LazyLoadScrollViewState extends State<LazyLoadScrollView> {
  LoadingStatus loadMoreStatus = LoadingStatus.STABLE;

  @override
  void didUpdateWidget(LazyLoadScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadMoreStatus = LoadingStatus.STABLE;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      child: widget.child,
      onNotification: (notification) => _onNotification(notification, context),
    );
  }

  bool _onNotification(Notification notification, BuildContext context) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.maxScrollExtent > notification.metrics.pixels &&
          notification.metrics.maxScrollExtent - notification.metrics.pixels <=
              widget.scrollOffset) {
        if (loadMoreStatus != null && loadMoreStatus == LoadingStatus.STABLE) {
          loadMoreStatus = LoadingStatus.LOADING;
          widget.endOfPageListener();
        }
      }
      return true;
    }
    if (notification is OverscrollNotification) {
      if (notification.overscroll > 0) {
        if (loadMoreStatus != null && loadMoreStatus == LoadingStatus.STABLE) {
          loadMoreStatus = LoadingStatus.LOADING;
          widget.endOfPageListener();
        }
      }
      return true;
    }
    return false;
  }
}
