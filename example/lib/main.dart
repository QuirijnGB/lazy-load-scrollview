import 'package:flutter/material.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Lazy Load Demo',
      home: MyHomePage(title: 'Lazy Load Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final scrollController = ScrollController();

  List<int> verticalData = [];
  List<int> horizontalData = [];

  final int increment = 10;

  @override
  void initState() {
    _loadMoreVertical();
    _loadMoreHorizontalAfter();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future _loadMoreVertical() async {
    // Add in an artificial delay
    await Future<void>.delayed(const Duration(seconds: 2));

    verticalData.addAll(
      List.generate(increment, (index) => verticalData.length + index),
    );
    setState(() {});
  }

  Future _loadMoreHorizontalBefore() async {
    // Add in an artificial delay
    await Future<void>.delayed(const Duration(seconds: 2));

    final firstIndex = horizontalData.first - 1;

    final previousToAdd = List.generate(
      increment,
      (index) => firstIndex - index,
    );

    horizontalData = [...previousToAdd.reversed, ...horizontalData];

    setState(() {});
  }

  Future _loadMoreHorizontalAfter() async {
    // Add in an artificial delay
    await Future<void>.delayed(const Duration(seconds: 2));

    horizontalData.addAll(
      List.generate(increment, (index) => horizontalData.length + index),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: LazyLoadScrollView(
        onLoadAfter: _loadMoreVertical,
        controller: scrollController,
        builder: (context, isLoadingAfter, _) {
          // FIXME: I don't think this is true
          // Scrollbar eats notifications ?? so we'll just use a scroll controller
          return Scrollbar(
            child: ListView(
              controller: scrollController,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Nested horizontal ListView',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 300.0,
                  child: LazyLoadScrollView(
                    onLoadAfter: _loadMoreHorizontalAfter,
                    onLoadBefore: _loadMoreHorizontalBefore,
                    builder: (
                      BuildContext context,
                      bool isLoadingAfter,
                      bool isLoadingBefore,
                    ) {
                      return CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        slivers: [
                          if (isLoadingBefore)
                            const SliverToBoxAdapter(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final position = horizontalData[index];

                                return DemoItem(
                                  position,
                                  key: ValueKey(position),
                                );
                              },
                              childCount: horizontalData.length,
                              findChildIndexCallback: (key) {
                                final valueKey = (key as ValueKey<int>).value;

                                return horizontalData.indexOf(valueKey);
                              },
                            ),
                          ),
                          if (isLoadingAfter)
                            const SliverToBoxAdapter(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Vertical ListView',
                    textAlign: TextAlign.center,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: verticalData.length,
                  itemBuilder: (context, position) {
                    return DemoItem(position);
                  },
                ),
                if (isLoadingAfter)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DemoItem extends StatelessWidget {
  final int position;

  const DemoItem(
    this.position, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
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
                  const SizedBox(width: 8.0),
                  Text("Item ${position.toString()}"),
                ],
              ),
              const Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque sed vulputate orci. Proin id scelerisque velit. Fusce at ligula ligula. Donec fringilla sapien odio, et faucibus tortor finibus sed. Aenean rutrum ipsum in sagittis auctor. Pellentesque mattis luctus consequat. Sed eget sapien ut nibh rhoncus cursus. Donec eget nisl aliquam, ornare sapien sit amet, lacinia quam.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
