import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: FlatButton(
            onPressed: () {},
            child: Image.asset(
              'assets/wm_nav_back_new_bg.png',
              fit: BoxFit.none,
            )),
        brightness: Brightness.light,
      ),
      body: Column(
        children: <Widget>[
          PointInfo(),
          Divider(
            color: Color(0xffe2e6ea),
            height: 1,
          ),
          SegmentButtons(),
          Divider(
            color: Color(0xffe2e6ea),
            height: 1,
          ),
          Expanded(child: PointTable()),
        ],
      ),
    );
  }
}

class PointInfo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PointInfoState();
  }
}

class PointInfoState extends State<PointInfo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                      child: Text(
                    '我的积分',
                    style: TextStyle(color: Color(0xff333333), fontSize: 15),
                  )),
                  Image.asset(
                    'assets/icon_6.png',
                    fit: BoxFit.none,
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '2421',
                        style: TextStyle(
                            color: Color(0xffff3530),
                            fontSize: 21,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    RaisedButton(
                      onPressed: () {},
                      child: Text(
                        '积分宝典',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      color: Color(0xff00a752),
                      elevation: 0,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '您有2300积分将于2017年12月31日清零',
                  style: TextStyle(color: Color(0xffff3530), fontSize: 13),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SegmentButtons extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SegmentButtonsState();
  }
}

class SegmentButtonsState extends State<SegmentButtons> {
  GlobalKey animationLineKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 44,
        child: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                FlatButton(
                  onPressed: () {
                    SlideTransition(position: null);
                  },
                  child: Text(
                    '全部',
                    style: TextStyle(color: Color(0xff00a752)),
                  ),
                ),
                FlatButton(onPressed: () {}, child: Text('获得')),
                FlatButton(onPressed: () {}, child: Text('消耗')),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 1,
                width: MediaQuery.of(context).size.width / 3,
                color: Colors.red,
              ),
            )
          ],
        )
//        alignment: MainAxisAlignment.spaceEvenly,
//        mainAxisSize: MainAxisSize.max,
        );
  }
}

class PointTable extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PointTableState();
  }
}

class PointTableState extends State<PointTable> {
  List<Widget> cells = Iterable.generate(20).map<Widget>((index) {
    return Cell();
  }).toList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        return cells[index];
      },
      separatorBuilder: (context, index) {
        return Column(
          children: <Widget>[
            Divider(
              color: Color(0xffe3e6e8),
              height: 1,
            ),
            Container(
              height: 10,
              color: Color(0xffe3e6e8),
            ),
            Divider(
              color: Color(0xffe3e5ea),
              height: 1,
            ),
          ],
        );
      },
      itemCount: cells.length,
      shrinkWrap: true,
    );
  }
}

class Cell extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CellState();
  }
}

class CellState extends State<Cell> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 17, bottom: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '纸箱回收赠送积分，订单号：BJ884578236476734',
                    style: TextStyle(color: Color(0xff333333), fontSize: 14),
                    maxLines: 2,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '2017-07-28 10:56:23',
                      style: TextStyle(color: Color(0xff999999), fontSize: 13),
                    ),
                  )
                ],
              ),
            ),
          ),
          Text(
            '+ 100.00',
            style: TextStyle(color: Color(0xffff3530), fontSize: 19),
          )
        ],
      ),
    );
  }
}
