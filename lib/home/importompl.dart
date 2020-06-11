import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/podcast_group.dart';
import '../state/subscribe_podcast.dart';
import '../state/download_state.dart';
import '../state/refresh_podcast.dart';
import '../type/episodebrief.dart';
import '../util/context_extension.dart';

class Import extends StatelessWidget {
  Widget importColumn(String text, BuildContext context) {
    return Container(
      color: context.primaryColorDark,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: 2.0, child: LinearProgressIndicator()),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              height: 20.0,
              alignment: Alignment.centerLeft,
              child: Text(text),
            ),
          ]),
    );
  }

  _autoDownloadNew(BuildContext context) async {
    final DBHelper dbHelper = DBHelper();
    var downloader = Provider.of<DownloadState>(context, listen: false);
    var result = await Connectivity().checkConnectivity();
    KeyValueStorage autoDownloadStorage =
        KeyValueStorage(autoDownloadNetworkKey);
    int autoDownloadNetwork = await autoDownloadStorage.getInt();
    if (autoDownloadNetwork == 1) {
      List<EpisodeBrief> episodes = await dbHelper.getNewEpisodes('all');
      // For safety
      if (episodes.length < 100)
        episodes.forEach((episode) {
          downloader.startTask(episode, showNotification: false);
        });
    } else if (result == ConnectivityResult.wifi) {
      List<EpisodeBrief> episodes = await dbHelper.getNewEpisodes('all');
      //For safety
      if (episodes.length < 100)
        episodes.forEach((episode) {
          downloader.startTask(episode, showNotification: false);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    GroupList groupList = Provider.of<GroupList>(context, listen: false);
    return Column(
      children: <Widget>[
        Consumer<SubscribeWorker>(
          builder: (_, subscribeWorker, __) {
            SubscribeItem item = subscribeWorker.currentSubscribeItem;
            switch (item.subscribeState) {
              case SubscribeState.start:
                return importColumn("Subscribe ${item.title}", context);
              case SubscribeState.subscribe:
                groupList.subscribeNewPodcast(item.id);
                return importColumn("Fetch data ${item.title}", context);
              case SubscribeState.fetch:
                //  groupList.updatePodcast(item.id);
                return importColumn("Subscribe success ${item.title}", context);
              case SubscribeState.exist:
                return importColumn(
                    "Subscribe failed, podcast existed ${item.title}", context);
              case SubscribeState.error:
                return importColumn(
                    "Subscribe failed, network error ${item.title}", context);
              default:
                return Center();
            }
          },
        ),
        Consumer<RefreshWorker>(
          builder: (context, refreshWorker, child) {
            RefreshItem item = refreshWorker.currentRefreshItem;
            if (refreshWorker.complete) {
              groupList.updateGroups();
              _autoDownloadNew(context);
            }
            switch (item.refreshState) {
              case RefreshState.fetch:
                return importColumn("Update ${item.title}", context);
              case RefreshState.error:
                return importColumn("Update error ${item.title}", context);
              default:
                return Center();
            }
          },
        )
      ],
    );
  }
}
