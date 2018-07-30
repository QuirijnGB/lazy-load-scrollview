import 'package:flutter/material.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Lazy Load Demo',
      home: new MyHomePage(title: 'Lazy Load Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<int> data = [];
  int currentLength = 0;

  final int increment = 10;

  @override
  void initState() {
    _loadMore();
    super.initState();
  }

  void _loadMore() {
    setState(() {
      for (var i = currentLength; i <= currentLength + increment; i++) {
        data.add(i);
      }
      currentLength = data.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: LazyLoadScrollView(
        onEndOfPage: () => _loadMore(),
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, position) {
            return new DemoItem(position);
          },
        ),
      ),
    );
  }
}

class DemoItem extends StatelessWidget {
  final int position;

  const DemoItem(
    this.position, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  color: Colors.grey,
                  height: 40.0,
                  width: 40.0,
                ),
                SizedBox(width: 8.0),
                Text("Item $position"),
              ],
            ),
            Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque sed vulputate orci. Proin id scelerisque velit. Fusce at ligula ligula. Donec fringilla sapien odio, et faucibus tortor finibus sed. Aenean rutrum ipsum in sagittis auctor. Pellentesque mattis luctus consequat. Sed eget sapien ut nibh rhoncus cursus. Donec eget nisl aliquam, ornare sapien sit amet, lacinia quam."),
          ],
        ),
      ),
    );
  }
}
