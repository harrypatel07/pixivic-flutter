import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'widget/nav_bar.dart';
import 'widget/papp_bar.dart';
import 'widget/menu_button.dart';
import 'widget/menu_list.dart';

import 'page/pic_page.dart';
import 'page/new_page.dart';
import 'page/user_page.dart';
import 'page/center_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixivic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Pixivic'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _textFieldController = TextEditingController();

  int _currentIndex = 0;
  bool _navBarAlone = false;
  var _pageController = PageController(initialPage: 0);
  bool _menuButtonActive = false;
  bool _menuButtonVisible = true;
  bool _menuListActive = false;
  
  bool _picModeIsSearch = false;
  DateTime _picDate = DateTime.now().subtract(Duration(days: 3));
  String _picDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 3)));
  String _picMode = 'day';
  DateTime _picLastDate = DateTime.now().subtract(Duration(days: 3));
  DateTime _picFirstDate = DateTime(2008, 1, 1);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 324, height: 576);

    return Scaffold(
      appBar: PappBar(
        title: widget.title,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: <Widget>[
          PageView.builder(
            itemCount: 4,                          //页面数量
            onPageChanged: _onPageChanged,         //页面切换
            controller: _pageController,
            itemBuilder: (context, index) {
              return Center(
                child: _getPageByIndex(index),     //每个页面展示的组件
              );
            },
          ),
          NavBar(_currentIndex, _onNavbarTap, _navBarAlone),
          MenuButton(_menuButtonActive, _menuButtonVisible, _onMenuButoonTap),
          MenuList(_menuListActive, _onMenuListCellTap),
        ],
      ),
    );
  }

  StatefulWidget _getPageByIndex(int index) {
    switch (index) {
      case 0:
        return PicPage.home(_picDateStr, _picMode, _picModeIsSearch);
      case 1:
        return CenterPage();
      case 2:
        return NewPage();
      case 3:
        return UserPage();
      default:
        return PicPage.home(_picDateStr, _picMode, _picModeIsSearch);
    }
  }

  void _onNavbarTap(int index) {
    // print('tap $index');
    setState(() {
      _pageController.jumpToPage(
        index);
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      // print('_onPageChanged: $index');
      _currentIndex = index;
      _menuButtonActive = false;
      if(index == 0) {
        _navBarAlone = false;
        _menuButtonVisible = true;
      }else {
        _navBarAlone = true;
        _menuButtonVisible = false;
      }
    });
  }

  void _onMenuButoonTap() {
    setState(() {
      _menuButtonActive = !_menuButtonActive;
      _menuListActive = !_menuListActive;
    });
  }

  void _onMenuListCellTap(String parameter) async{
    if(parameter == 'new_date') {
        DateTime newDate = await showDatePicker(
          context: context,
          initialDate: _picDate,
          firstDate: _picFirstDate,
          lastDate: _picLastDate,
          // locale: Locale('zh')
        );
        if(newDate != null) {
          setState(() {
            print(newDate);
            _picDate = newDate;
            _picDateStr = DateFormat('yyyy-MM-dd').format(_picDate);
            _menuButtonActive = !_menuButtonActive;
            _menuListActive = !_menuListActive;
        });
        }
      }else if(parameter == 'search') {
        showDialog(context: context,builder: (context) {
          return AlertDialog(
            title: Text('搜索关键词'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "输入关键词"),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('提交'),
                onPressed: () {
                  if(_textFieldController.text == '') {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pop();
                    setState(() {
                      _picModeIsSearch = true;
                      _picMode = _textFieldController.text;
                      _textFieldController.clear();
                      _menuButtonActive = !_menuButtonActive;
                      _menuListActive = !_menuListActive; 
                    });
                  }
                },
              )
            ],
          );
        },);
      }else {
        setState(() {
          _picMode = parameter;
          _picModeIsSearch = false;
          _menuButtonActive = !_menuButtonActive;
          _menuListActive = !_menuListActive; 
        });
      }     
  }
}
