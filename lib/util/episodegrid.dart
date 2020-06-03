import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:line_icons/line_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:auto_animated/auto_animated.dart';
import 'open_container.dart';

import '../state/audiostate.dart';
import '../type/episodebrief.dart';
import '../episodes/episodedetail.dart';
import '../local_storage/sqflite_localpodcast.dart';
import 'colorize.dart';
import 'context_extension.dart';
import 'custompaint.dart';

enum Layout { three, two, one }

class EpisodeGrid extends StatelessWidget {
  final List<EpisodeBrief> episodes;
  final bool showFavorite;
  final bool showDownload;
  final bool showNumber;
  final int episodeCount;
  final Layout layout;
  final bool reverse;
  final int initNum;
  Future<int> _isListened(EpisodeBrief episode) async {
    DBHelper dbHelper = DBHelper();
    return await dbHelper.isListened(episode.enclosureUrl);
  }

  Future<bool> _isLiked(EpisodeBrief episode) async {
    DBHelper dbHelper = DBHelper();
    return await dbHelper.isLiked(episode.enclosureUrl);
  }

  String _stringForSeconds(double seconds) {
    if (seconds == null) return null;
    return '${(seconds ~/ 60)}:${(seconds.truncate() % 60).toString().padLeft(2, '0')}';
  }

  EpisodeGrid({
    Key key,
    @required this.episodes,
    this.initNum = 12,
    this.showDownload = false,
    this.showFavorite = false,
    this.showNumber = false,
    this.episodeCount = 0,
    this.layout = Layout.three,
    this.reverse,
  }) : super(key: key);

  Widget _title(EpisodeBrief episode) => Container(
        alignment:
            layout == Layout.one ? Alignment.centerLeft : Alignment.topLeft,
        padding: EdgeInsets.only(top: 2.0),
        child: Text(
          episode.title,
          maxLines: layout == Layout.one ? 1 : 4,
          overflow:
              layout == Layout.one ? TextOverflow.ellipsis : TextOverflow.fade,
        ),
      );
  Widget _circleImage(BuildContext context,
          {EpisodeBrief episode, Color color, bool boo}) =>
      Container(
        height: context.width / 16,
        width: context.width / 16,
        child: boo
            ? Center()
            : CircleAvatar(
                backgroundColor: color.withOpacity(0.5),
                backgroundImage: FileImage(File("${episode.imagePath}")),
              ),
      );
  Widget _listenIndicater(BuildContext context,
          {EpisodeBrief episode, int isListened}) =>
      Selector<AudioPlayerNotifier, Tuple2<EpisodeBrief, bool>>(
          selector: (_, audio) => Tuple2(audio.episode, audio.playerRunning),
          builder: (_, data, __) {
            return (episode.enclosureUrl == data.item1?.enclosureUrl &&
                    data.item2)
                ? Container(
                    height: 20,
                    width: 20,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: WaveLoader(color: context.accentColor))
                : layout == Layout.two && isListened > 0
                    ? Container(
                        height: 20,
                        width: 20,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: context.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: CustomPaint(
                            painter: ListenedAllPainter(
                          Colors.white,
                        )),
                      )
                    : Center();
          });

  Widget _downloadIndicater(BuildContext context, {EpisodeBrief episode}) =>
      showDownload || layout != Layout.three
          ? Container(
              child: (episode.enclosureUrl != episode.mediaId)
                  ? Container(
                      height: 20,
                      width: 20,
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: context.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.done_all,
                        size: 15,
                        color: Colors.white,
                      ),
                    )
                  : Center(),
            )
          : Center();
  Widget _isNewIndicator(EpisodeBrief episode) => episode.isNew == 1
      ? Container(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text('New',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
        )
      : Center();

  Widget _numberIndicater(BuildContext context, {int index, Color color}) =>
      showNumber
          ? Container(
              alignment: Alignment.topRight,
              child: Text(
                reverse
                    ? (index + 1).toString()
                    : (episodeCount - index).toString(),
                style: GoogleFonts.teko(
                  textStyle: TextStyle(
                    fontSize: context.width / 24,
                    color: color,
                  ),
                ),
              ),
            )
          : Center();
  Widget _pubDate(BuildContext context, {EpisodeBrief episode, Color color}) =>
      Text(
        episode.dateToString(),
        style: TextStyle(
            fontSize: context.width / 35,
            color: color,
            fontStyle: FontStyle.italic),
      );

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    Offset _offset;
    _showPopupMenu(Offset offset, EpisodeBrief episode, BuildContext context,
        bool isPlaying, bool isInPlaylist) async {
      var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
      double left = offset.dx;
      double top = offset.dy;
      await showMenu<int>(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        context: context,
        position: RelativeRect.fromLTRB(left, top, _width - left, 0),
        items: <PopupMenuEntry<int>>[
          PopupMenuItem(
            value: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Icon(
                  LineIcons.play_circle_solid,
                  color: Theme.of(context).accentColor,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                ),
                !isPlaying ? Text('Play') : Text('Playing'),
              ],
            ),
          ),
          PopupMenuItem(
              value: 1,
              child: Row(
                children: <Widget>[
                  Icon(
                    LineIcons.clock_solid,
                    color: Colors.red,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                  ),
                  !isInPlaylist ? Text('Later') : Text('Remove')
                ],
              )),
        ],
        elevation: 5.0,
      ).then((value) {
        if (value == 0) {
          if (!isPlaying) audio.episodeLoad(episode);
        } else if (value == 1) {
          if (!isInPlaylist) {
            audio.addToPlaylist(episode);
            Fluttertoast.showToast(
              msg: 'Added to playlist',
              gravity: ToastGravity.BOTTOM,
            );
          } else {
            audio.delFromPlaylist(episode);
            Fluttertoast.showToast(
              msg: 'Removed from playlist',
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
      });
    }

    final options = LiveOptions(
      delay: Duration.zero,
      showItemInterval: Duration(milliseconds: 50),
      showItemDuration: Duration(milliseconds: 50),
    );
    final scrollController = ScrollController();
    return SliverPadding(
      padding: const EdgeInsets.only(
          top: 10.0, bottom: 5.0, left: 15.0, right: 15.0),
      sliver: LiveSliverGrid.options(
        controller: scrollController,
        options: options,
        itemCount: episodes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio:
              layout == Layout.three ? 1 : layout == Layout.two ? 1.5 : 4,
          crossAxisCount:
              layout == Layout.three ? 3 : layout == Layout.two ? 2 : 1,
          mainAxisSpacing: 6.0,
          crossAxisSpacing: 6.0,
        ),
        itemBuilder: (context, index, animation) {
          Color _c = (Theme.of(context).brightness == Brightness.light)
              ? episodes[index].primaryColor.colorizedark()
              : episodes[index].primaryColor.colorizeLight();
          return FadeTransition(
            opacity: Tween<double>(
              begin: index < initNum ? 0 : 1,
              end: 1,
            ).animate(animation),
            child: Selector<AudioPlayerNotifier,
                Tuple2<EpisodeBrief, List<String>>>(
              selector: (_, audio) => Tuple2(audio?.episode,
                  audio.queue.playlist.map((e) => e.enclosureUrl).toList()),
              builder: (_, data, __) => OpenContainerWrapper(
                episode: episodes[index],
                closedBuilder: (context, action, boo) => FutureBuilder<int>(
                    future: _isListened(episodes[index]),
                    initialData: 0,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      return Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                            color: snapshot.data > 0
                                ? context.brightness == Brightness.light
                                    ? context.primaryColor
                                    : Color.fromRGBO(40, 40, 40, 1)
                                : context.scaffoldBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: context.brightness == Brightness.light
                                    ? context.primaryColor
                                    : Color.fromRGBO(40, 40, 40, 1),
                                blurRadius: 0.5,
                                spreadRadius: 0.5,
                              ),
                            ]),
                        alignment: Alignment.center,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                            onTapDown: (details) => _offset = Offset(
                                details.globalPosition.dx,
                                details.globalPosition.dy),
                            onLongPress: () => _showPopupMenu(
                                _offset,
                                episodes[index],
                                context,
                                data.item1 == episodes[index],
                                data.item2
                                    .contains(episodes[index].enclosureUrl)),
                            onTap: action,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5.0)),
                                border: Border.all(
                                  color: context.brightness == Brightness.light
                                      ? context.primaryColor
                                      : context.scaffoldBackgroundColor,
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    flex: layout == Layout.one ? 1 : 2,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        layout != Layout.one
                                            ? _circleImage(context,
                                                episode: episodes[index],
                                                color: _c,
                                                boo: boo)
                                            : _pubDate(context,
                                                episode: episodes[index],
                                                color: _c),
                                        Spacer(),
                                        _listenIndicater(context,
                                            episode: episodes[index],
                                            isListened: snapshot.data),
                                        _downloadIndicater(context,
                                            episode: episodes[index]),
                                        _isNewIndicator(episodes[index]),
                                        _numberIndicater(context,
                                            index: index, color: _c)
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: layout == Layout.one ? 3 : 5,
                                    child: layout != Layout.one
                                        ? _title(episodes[index])
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              _circleImage(context,
                                                  episode: episodes[index],
                                                  color: _c,
                                                  boo: boo),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Expanded(
                                                  child:
                                                      _title(episodes[index]))
                                            ],
                                          ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        layout != Layout.one
                                            ? Align(
                                                alignment: Alignment.bottomLeft,
                                                child: _pubDate(context,
                                                    episode: episodes[index],
                                                    color: _c),
                                              )
                                            : SizedBox(width: 1),
                                        Spacer(),
                                        layout != Layout.three &&
                                                episodes[index].duration != 0
                                            ? Container(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  _stringForSeconds(
                                                      episodes[index]
                                                          .duration
                                                          .toDouble()),
                                                  style: TextStyle(
                                                      fontSize: _width / 35),
                                                ),
                                              )
                                            : Center(),
                                        episodes[index].duration == 0 ||
                                                episodes[index]
                                                        .enclosureLength ==
                                                    null ||
                                                episodes[index]
                                                        .enclosureLength ==
                                                    0 ||
                                                layout == Layout.three
                                            ? Center()
                                            : Text(
                                                '|',
                                                style: TextStyle(
                                                  fontSize: _width / 35,
                                                  // color: _c,
                                                  // fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                        layout != Layout.three &&
                                                episodes[index]
                                                        .enclosureLength !=
                                                    null &&
                                                episodes[index]
                                                        .enclosureLength !=
                                                    0
                                            ? Container(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  ((episodes[index]
                                                                  .enclosureLength) ~/
                                                              1000000)
                                                          .toString() +
                                                      'MB',
                                                  style: TextStyle(
                                                      fontSize: _width / 35),
                                                ),
                                              )
                                            : Center(),
                                        Padding(
                                          padding: EdgeInsets.all(1),
                                        ),
                                        showFavorite || layout != Layout.three
                                            ? FutureBuilder<bool>(
                                                future:
                                                    _isLiked(episodes[index]),
                                                initialData: false,
                                                builder: (context, snapshot) =>
                                                    Container(
                                                  alignment: Alignment.center,
                                                  child: (snapshot.data)
                                                      ? IconTheme(
                                                          data: IconThemeData(
                                                              size:
                                                                  _width / 35),
                                                          child: Icon(
                                                            Icons.favorite,
                                                            color: Colors.red,
                                                          ),
                                                        )
                                                      : Center(),
                                                ),
                                              )
                                            : Center(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OpenContainerWrapper extends StatelessWidget {
  const OpenContainerWrapper({
    this.closedBuilder,
    this.episode,
    this.playerRunning,
  });

  final OpenContainerBuilder closedBuilder;
  final EpisodeBrief episode;
  final bool playerRunning;

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerNotifier, bool>(
      selector: (_, audio) => audio.playerRunning,
      builder: (_, data, __) => OpenContainer(
        playerRunning: data,
        flightWidget: CircleAvatar(
          backgroundImage: FileImage(File("${episode.imagePath}")),
        ),
        transitionDuration: Duration(milliseconds: 400),
        beginColor: Theme.of(context).primaryColor,
        endColor: Theme.of(context).primaryColor,
        closedColor: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).primaryColor
            : Theme.of(context).scaffoldBackgroundColor,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        openElevation: 0,
        closedElevation: 0,
        openShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0))),
        closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _, bool boo) {
          return EpisodeDetail(
            episodeItem: episode,
            hide: boo,
          );
        },
        tappable: true,
        closedBuilder: closedBuilder,
      ),
    );
  }
}
