import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Infinite Page Scroll',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InfiniteScrollExample(),
    );
  }
}

class InfiniteScrollExample extends StatefulWidget {
  const InfiniteScrollExample({super.key});

  @override
  State<InfiniteScrollExample> createState() => _InfiniteScrollExampleState();
}

class _InfiniteScrollExampleState extends State<InfiniteScrollExample> {
  final int _pageSize = 20;

  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      //get api /beers list from pages
      final newItems = await RemoteApi.getBeerList(pageKey, _pageSize);
      //Check if it is last page
      final isLastPage = newItems!.length < _pageSize;
      //if it is last page then append last page else append new page
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        //Appending new page when it is not last page
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    }
    // Handle error in catch
    catch (error) {
      print(_pagingController.error);
      //Sets the error in controller
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) =>
      //Refrsh Indicator pull down
      RefreshIndicator(
        onRefresh: () => Future.sync(
          //Refresh through page controllers
          () => _pagingController.refresh(),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Pagination Scroll Flutter Template"),
          ),
          //Page Listview with divider as a separation
          body: PagedListView<int, dynamic>.separated(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<dynamic>(
              animateTransitions: true,
              itemBuilder: (_, item, index) => ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(item["image_url"]),
                ),
                title: Text(item["name"]),
              ),
            ),
            separatorBuilder: (_, index) => const Divider(),
          ),
        ),
      );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class RemoteApi {
  static Future<List<dynamic>?> getBeerList(
    //Page means on which page you are currently
    int page,
    //Limit per page you want to set
    int limit,
  ) async {
    try {
      //Request the API on url
      final response = await http.get(
        Uri.parse(
          'https://api.punkapi.com/v2/beers?'
          'page=$page'
          '&per_page=$limit',
        ),
      );
      if (response.statusCode == 200) {
        //Decode the response
        final mybody = jsonDecode(response.body);

        return mybody;
      }
    } catch (e) {
      print("Error $e");
    }
    return null;
  }
}
