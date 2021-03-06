import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'package:pixivic/data/common.dart';
import 'package:requests/requests.dart';
import 'package:bot_toast/bot_toast.dart';

import '../widget/papp_bar.dart';
import '../widget/suggestion_bar.dart';
import 'pic_page.dart';
import '../data/texts.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();

  final String searchKeywordsIn;

  SearchPage({
    @required this.searchKeywordsIn,
  });
}

class _SearchPageState extends State<SearchPage> {
  String searchKeywords;
  PicPage picPage;
  SuggestionBar suggestionBar;
  List suggestions;
  bool searchManga = false;
  GlobalKey<PappBarState> pappbarKey = GlobalKey();
  TextZhSearchPage text = TextZhSearchPage();

  bool currentOnLoading = true;
  int currentNum = 60;
  List currentTags;

  GlobalKey<SuggestionBarState> _suggestionBarKey = GlobalKey();

  @override
  void initState() {
    searchKeywords = widget.searchKeywordsIn;
    suggestionBar = SuggestionBar(searchKeywords, _onSearch, _suggestionBarKey);

    if (searchKeywords != '') {
      picPage = PicPage.search(
        searchKeywords: searchKeywords,
        isManga: searchManga,
      );
    }

    _currentLoad().then((value) {
      setState(() {
        currentOnLoading = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PappBar.search(
          searchKeywordsIn: searchKeywords,
          searchFucntion: _onSearch,
          key: pappbarKey,
        ),
        body: searchKeywords != ''
            ? ListView(
                children: <Widget>[
                  suggestionBar,
                  Center(
                    child: Container(
                      width: ScreenUtil().setWidth(324),
                      height: ScreenUtil().setHeight(522), //待测试
                      color: Colors.white,
                      child: picPage,
                    ),
                  ),
                ],
              )
            : currentOnLoading
                ? Lottie.asset('image/loading-box.json')
                : SizedBox(
                    height: ScreenUtil().setHeight(576),
                    child: Flex(
                      direction: Axis.vertical,
                      children: <Widget>[
                        Flexible(
                          flex: 35,
                          child: Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(
                                  bottom: ScreenUtil().setHeight(5),
                                  top: ScreenUtil().setHeight(5),
                                  left: ScreenUtil().setWidth(4)),
                              height: ScreenUtil().setHeight(35),
                              child: Text(
                                text.everybodyIsWatching,
                                style: TextStyle(color: Colors.blueGrey),
                              )),
                        ),
                        Expanded(
                          flex: 541,
                          child: StaggeredGridView.countBuilder(
                            controller: ScrollController()
                              ..addListener(() {
                                FocusScope.of(context).unfocus();
                              }),
                            physics: ClampingScrollPhysics(),
                            crossAxisCount: 3,
                            itemCount: currentTags.length,
                            padding: EdgeInsets.only(
                                left: ScreenUtil().setWidth(1),
                                right: ScreenUtil().setWidth(1)),
                            itemBuilder: (BuildContext context, int index) =>
                                _currentCell(
                                    currentTags[index]['name'],
                                    currentTags[index]['translatedName'],
                                    currentTags[index]['illustration']
                                        ['imageUrls'][0]['medium'],
                                    currentTags[index]['illustration']
                                        ['sanityLevel']),
                            staggeredTileBuilder: (index) =>
                                StaggeredTile.fit(1),
                            // mainAxisSpacing: 4.0,
                            // crossAxisSpacing: 4.0,
                          ),
                        ),
                      ],
                    ),
                  ));
  }

  _onSearch(String value, {bool fromCurrent}) {
    FocusScope.of(context).unfocus();
    setState(() {
      searchKeywords = value;
      if (value != '')
        picPage = PicPage.search(
          searchKeywords: searchKeywords,
          isManga: searchManga,
        );
    });
    pappbarKey.currentState.changeSearchKeywords(value);
    if (fromCurrent != null && fromCurrent)
      suggestionBar =
          SuggestionBar(searchKeywords, _onSearch, _suggestionBarKey);
    else
      try {
        _suggestionBarKey.currentState.reloadSearchWords(value);
      } catch (e) {
        suggestionBar =
            SuggestionBar(searchKeywords, _onSearch, _suggestionBarKey);
      }
  }

  _currentLoad() async {
    String _picDateStr = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(Duration(days: 3)));

    var response = await Requests.get(
      'https://api.pixivic.com/trendingTags?date=$_picDateStr',
    ).catchError((e) {
      BotToast.showSimpleNotification(title: text.connectError);
    });

    response.raiseForStatus();
    if (response.statusCode == 200) {
      currentTags = jsonDecode(response.content())['data'];
      return false;
    } else {
      BotToast.showSimpleNotification(title: text.getCurrentError);
      return true;
    }
  }

  _currentCell(String jpTitle, String transTitle, String url, int sanityLevel) {
    if (sanityLevel > prefs.getInt('sanityLevel'))
      return SizedBox();
    else
      return Material(
        child: InkWell(
          onTap: () {
            FocusScope.of(context).unfocus();
            _onSearch(jpTitle, fromCurrent: true);
          },
          child: Container(
            alignment: Alignment.topCenter,
            width: ScreenUtil().setWidth(104),
            height: ScreenUtil().setWidth(104),
            padding: EdgeInsets.only(top: ScreenUtil().setWidth(60)),
            margin: EdgeInsets.all(ScreenUtil().setWidth(1)),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                image: DecorationImage(
                    fit: BoxFit.cover,
                    colorFilter:
                        ColorFilter.mode(Colors.black26, BlendMode.darken),
                    image: AdvancedNetworkImage(
                      url,
                      header: {'Referer': 'https://app-api.pixiv.net'},
                      useDiskCache: true,
                      cacheRule: CacheRule(maxAge: const Duration(days: 7)),
                    ))),
            child: Column(
              children: <Widget>[
                Text(
                  '#$jpTitle',
                  textAlign: TextAlign.center,
                  strutStyle: StrutStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                Text(
                  transTitle,
                  textAlign: TextAlign.center,
                  strutStyle: StrutStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                )
              ],
            ),
          ),
        ),
      );
  }
}
