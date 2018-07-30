library lazy_load_scrollview;

import 'package:flutter/widgets.dart';

enum LoadingStatus { LOADING, STABLE }

/// Signature for EndOfPageListeners
typedef void EndOfPageListenerCallback();

/// A widget that wraps a [ScrollView] and will trigger [onEndOfPage] when it
/// reaches the bottom of the list
class LazyLoadScrollView extends StatefulWidget {
  /// The [ScrollView] that this widget watches for changes on
  final ScrollView child;

  /// Called when the [child] reaches the end of the list
  final EndOfPageListenerCallback onEndOfPage;

  /// The offset to take into account when triggering [onEndOfPage] in pixels
  final int scrollOffset;

  @override
  State<StatefulWidget> createState() => LazyLoadScrollViewState();

  LazyLoadScrollView({
    Key key,
    @required this.child,
    @required this.onEndOfPage,
    this.scrollOffset = 100,
  })  : assert(onEndOfPage != null),
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
          widget.onEndOfPage();
        }
      }
      return true;
    }
    if (notification is OverscrollNotification) {
      if (notification.overscroll > 0) {
        if (loadMoreStatus != null && loadMoreStatus == LoadingStatus.STABLE) {
          loadMoreStatus = LoadingStatus.LOADING;
          widget.onEndOfPage();
        }
      }
      return true;
    }
    return false;
  }
}
