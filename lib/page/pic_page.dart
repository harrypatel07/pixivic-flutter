import 'package:flutter/material.dart';
// import 'dart:async';
import 'dart:convert';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:requests/requests.dart';
import 'package:random_color/random_color.dart';

import 'pic_detail_page.dart';

class PicPage extends StatefulWidget {
  @override
  _PicPageState createState() => _PicPageState();

  PicPage(this.picDate, this.picMode, this.modeIsSearch,
      {this.relatedId = 0, this.jsonMode = 'home'});
  PicPage.home(this.picDate, this.picMode, this.modeIsSearch,
      {this.relatedId = 0, this.jsonMode = 'home'});
  PicPage.related(this.relatedId,
      {this.picDate = '',
      this.picMode = '',
      this.modeIsSearch = false,
      this.jsonMode = 'related'});

  final String picDate;
  final String picMode;
  final bool modeIsSearch;
  final num relatedId;
  // jsonMode could be set to 'home, related, Spotlight, tag, artist'
  final String jsonMode;
}

class _PicPageState extends State<PicPage> {
  // picList - 图片的JSON文件列表
  // picTotalNum - picList 中项目的总数（非图片总数，因为单个项目有可能有多个图片）

  List picList;
  int picTotalNum;
  RandomColor _randomColor = RandomColor();

  @override
  void initState() {
    _getJsonList().then((value) {
      setState(() {
        picList = value;
        picTotalNum = value.length;
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(PicPage oldWidget) {
    _getJsonList().then((value) {
      setState(() {
        picList = value;
        picTotalNum = value.length;
      });
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (picList == null) {
      return Center();
    } else {
      return Container(
          child: StaggeredGridView.countBuilder(
        crossAxisCount: 2,
        itemCount: picTotalNum,
        itemBuilder: (BuildContext context, int index) => imageCell(index),
        staggeredTileBuilder: (index) => StaggeredTile.fit(1),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ));
    }
  }

  _getJsonList() async {
    // 获取所有的图片数据
    String url;
    if (widget.jsonMode == 'home') {
      if (!widget.modeIsSearch) {
        url =
            'https://api.pixivic.com/ranks?page=1&date=${widget.picDate}&mode=${widget.picMode}&pageSize=500';
      } else {
        url =
            'https://api.pixivic.com/illustrations?illustType=illust&searchType=original&maxSanityLevel=6&page=1&keyword=${widget.picMode}&pageSize=30';
      }
    }
    else if(widget.jsonMode == 'related') {
      url = 'https://api.pixivic.com/illusts/${widget.relatedId}/related?page=1&pageSize=30';
    }

    var requests = await Requests.get(url);
    requests.raiseForStatus();
    List jsonList = jsonDecode(requests.content())['data'];
    return (jsonList);
  }

  List _reviewPicUrlNumAspectRatio(int index) {
    // 预览图片的地址、数目、以及长宽比
    // String url = picList[index]['imageUrls'][0]['squareMedium'];
    String url = picList[index]['imageUrls'][0]['medium']; //medium large
    int number = picList[index]['pageCount'];
    double width = picList[index]['width'].toDouble();
    double height = picList[index]['height'].toDouble();
    return [url, number, width, height];
  }

  Widget imageCell(int index) {
    Color color = _randomColor.randomColor();
    Map picMapData = Map.from(picList[index]);
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PicDetailPage(picMapData)));
        },
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.width *
                0.49 /
                _reviewPicUrlNumAspectRatio(index)[2] *
                _reviewPicUrlNumAspectRatio(index)[3],
            minWidth: MediaQuery.of(context).size.width * 0.41,
          ),
          child: Hero(
            tag: 'imageHero' + _reviewPicUrlNumAspectRatio(index)[0],
            child: Image.network(
              _reviewPicUrlNumAspectRatio(index)[0],
              headers: {'Referer': 'https://app-api.pixiv.net'},
              fit: BoxFit.fill,
              height: MediaQuery.of(context).size.width *
                  0.49 /
                  _reviewPicUrlNumAspectRatio(index)[2] *
                  _reviewPicUrlNumAspectRatio(index)[3],
              width: MediaQuery.of(context).size.width * 0.41,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }
                return Container(
                  child: AnimatedOpacity(
                    child: frame == null ? Container(color: color) : child,
                    opacity: frame == null ? 0.3 : 1,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOut,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
