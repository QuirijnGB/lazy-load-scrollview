# Lazy load scrollview

A wrapper for a ScrollView that will enable lazy loading

## Usage


Add `lazy_load_scrollview` dependency to your `pubspec.yaml`:

```yaml
dependencies:
  lazy_load_scrollview: 0.0.1
```


In your Dart code, import `package:lazy_load_scrollview/lazy_load_scrollview.dart`
Then you can wrap your `ListView` or `GridView` with the `LazyLoadScrollView`.
Make sure you add an `endOfPageListener` which will receive the call when the bottom of the list has been reached.

```dart
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';


@override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: LazyLoadScrollView(
        endOfPageListener: () => loadMore(),
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, position) {
            return Text("Position $position");
          },
        ),
      ),
    );
}
```

## Class definition

```dart

LazyLoadScrollView(
  endOfPageListener: () => loadMore(), // The callback when reaching the end of the list
  scrollOffset: 100 // Pixels from the bottom that should trigger a callback 
  child: Widget, // A subclass of `ScrollView`
);

```
