import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// TODO: How does this know it's reached the end of the list?
/// A function signature for a builder that receives loading widgets to be
/// inserted into a ListView when further data is being fetched.
typedef LazyLoadBuilder = Widget Function(
  BuildContext context,
  bool isLoadingAfter,
  bool isLoadingBefore,
);

class LazyLoadScrollView extends StatefulWidget {
  /// A lazy builder that will be used to create the list widget. It also
  /// carries the context of the child and a loading widget to be inserted into
  /// the ListViews.
  ///
  /// Note, the direct child of this widget should be the [ListView]. If it is
  /// not and the [ListView] is further down the tree then it's likely that this
  /// will Builder will fail to recognize scroll events unless [ignoreDepth] is
  /// set to true.
  final LazyLoadBuilder builder;

  /// The offset from the end at which the [onLoadBefore] or [onLoadAfter] will
  /// be called.
  final double scrollOffset;

  /// Called when more content is needed at the end of the main scroll axis
  final AsyncCallback? onLoadAfter;

  /// Called when more content is needed at the start of the main scroll axis
  final AsyncCallback? onLoadBefore;

  final Duration timeout;

  /// The duration until either [onLoadBefore] or [onLoadAfter] is called.
  /// The debounce strategy is eager. That means the callback will be called
  /// first then further calls will be ignored until the timeout expires.
  final Duration debounceDuration;

  /// Whether to ignore the depth of the [ListView] when calling [onLoadBefore]
  /// or [onLoadAfter]. This value is ignored if [controller] is set.
  final bool ignoreDepth;

  /// A check that specifies whether a [ScrollNotification] should be
  /// handled by this widget.
  ///
  /// By default, checks whether `notification.depth == 0`. That means if the
  /// scrollbar is wrapped around multiple [ScrollView]s, it only responds to the
  /// nearest scrollView and shows the corresponding scrollbar thumb.
  ///
  /// Copied from [RawScrollBar]
  ///
  /// This value is ignored [controller] is non null or [ignoreDepth] is true.
  final ScrollNotificationPredicate? notificationPredicate;

  /// This widget can either listen to notifications through a
  /// [NotificationListener] or it can listen to a [ScrollListener] and handle
  /// the scroll events directly.
  final ScrollController? controller;

  const LazyLoadScrollView({
    Key? key,
    required this.builder,
    this.onLoadAfter,
    this.onLoadBefore,
    this.scrollOffset = 100.0,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.timeout = const Duration(seconds: 10),
    this.ignoreDepth = false,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.controller,
  }) : super(key: key);

  @override
  State<LazyLoadScrollView> createState() => _LazyListBuilderState();
}

class _LazyListBuilderState extends State<LazyLoadScrollView> {
  AxisDirection? scrollDirection;

  bool isLoadingBefore = false;

  bool isLoadingAfter = false;

  Timer? timer;

  Future<void> loadBefore() async {
    if (widget.onLoadBefore == null || isLoadingBefore) return;

    // If we have a timer going, just return early.
    if (timer?.isActive ?? false) {
      return;
    } else {
      setState(() => isLoadingBefore = true);

      if (mounted) {
        await widget.onLoadBefore?.call().timeout(widget.timeout);
        setState(() => isLoadingBefore = false);
      }

      timer = Timer(widget.debounceDuration, () {});
    }
  }

  Future<void> loadAfter() async {
    if (widget.onLoadAfter == null || isLoadingAfter) return;

    if (timer?.isActive ?? false) {
      return;
    } else {
      setState(() => isLoadingAfter = true);

      if (mounted) {
        // TODO: Will these need completers to correctly handle errors?
        await widget.onLoadAfter?.call().timeout(widget.timeout);
        setState(() => isLoadingAfter = false);
      }

      timer = Timer(widget.debounceDuration, () {});
    }
  }

  @override
  void initState() {
    widget.controller?.addListener(_scrollListener);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LazyLoadScrollView oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_scrollListener);
      widget.controller?.addListener(_scrollListener);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_scrollListener);
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller != null) {
      return widget.builder(context, isLoadingAfter, isLoadingBefore);
    }

    return NotificationListener<ScrollNotification>(
      child: widget.builder(context, isLoadingAfter, isLoadingBefore),
      onNotification: (notification) {
        if (widget.ignoreDepth ||
            (widget.notificationPredicate?.call(notification) ?? false)) {
          final axis = notification.metrics.axis;
          final axisDirection = notification.metrics.axisDirection;
          final extentBefore = notification.metrics.extentBefore;
          final extentAfter = notification.metrics.extentAfter;

          if (notification is ScrollUpdateNotification) {
            final deltaOffset = notification.dragDetails?.delta;

            if (deltaOffset != null) {
              if (deltaOffset.dx != 0 && axis == Axis.horizontal) {
                if (deltaOffset.dx < 0) {
                  scrollDirection = AxisDirection.right;
                } else {
                  scrollDirection = AxisDirection.left;
                }
              }

              if (deltaOffset.dy != 0 && axis == Axis.vertical) {
                if (deltaOffset.dy < 0) {
                  scrollDirection = AxisDirection.down;
                } else {
                  scrollDirection = AxisDirection.up;
                }
              }
            }

            _handleScrollUpdate(
              axis: axis,
              axisDirection: axisDirection,
              extentAfter: extentAfter,
              extentBefore: extentBefore,
            );
          }

          if (notification is OverscrollNotification) {
            _handleOverScroll(
              axisDirection: axisDirection,
              extentAfter: extentAfter,
              extentBefore: extentBefore,
            );
          }
        }

        return false;
      },
    );
  }

  void _scrollListener() {
    // Assume non-null otherwise it wouldn't have gotten called.
    final controller = widget.controller!;
    final axis = controller.position.axis;
    final axisDirection = controller.position.axisDirection;
    final extentBefore = controller.position.extentBefore;
    final extentAfter = controller.position.extentAfter;
    final userScrollDirection = controller.position.userScrollDirection;

    switch (userScrollDirection) {
      case ScrollDirection.idle:
        return;
      case ScrollDirection.forward:
        switch (axis) {
          case Axis.horizontal:
            scrollDirection = AxisDirection.right;
            break;
          case Axis.vertical:
            scrollDirection = AxisDirection.up;
            break;
        }
        break;
      case ScrollDirection.reverse:
        switch (axis) {
          case Axis.horizontal:
            scrollDirection = AxisDirection.left;
            break;
          case Axis.vertical:
            scrollDirection = AxisDirection.down;
            break;
        }
        break;
    }

    _handleScrollUpdate(
      axis: axis,
      axisDirection: axisDirection,
      extentAfter: extentAfter,
      extentBefore: extentBefore,
    );

    if (controller.position.outOfRange) {
      _handleOverScroll(
        axisDirection: axisDirection,
        extentAfter: extentAfter,
        extentBefore: extentBefore,
      );
    }
  }

  void _handleScrollUpdate({
    required Axis axis,
    required AxisDirection axisDirection,
    required double extentAfter,
    required double extentBefore,
  }) {
    // scrollDirection comes from widget state
    if (axisDirection == scrollDirection &&
        extentAfter <= widget.scrollOffset) {
      loadAfter();
    }

    if (flipAxisDirection(axisDirection) == scrollDirection &&
        extentBefore <= widget.scrollOffset) {
      loadBefore();
    }
  }

  void _handleOverScroll({
    required AxisDirection axisDirection,
    required double extentAfter,
    required double extentBefore,
  }) {
    final _scrollDirection = scrollDirection;
    assert(_scrollDirection != null);

    if (_scrollDirection != null) {
      if (axisDirection == _scrollDirection && extentAfter == 0) {
        loadAfter();
      }

      if (flipAxisDirection(axisDirection) == _scrollDirection &&
          extentBefore == 0) {
        loadBefore();
      }
    }
  }
}
