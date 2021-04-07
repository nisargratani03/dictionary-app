import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dictionary',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _url = "https://owlbot.info/api/v4/dictionary/";
  String _token = "90e743b423f895b402701f826629e624293c9901";
  TextEditingController _controller = TextEditingController();
  StreamController _streamController;
  Stream _stream;

  Timer _debounce;

  _search() async {
    if (_controller.text == null || _controller.text.length == 0) {
      _streamController.add(null);
      return;
    }

    _streamController.add("waiting");
    try {
      Response response = await get(_url + _controller.text.trim(),
          headers: {"Authorization": "Token " + _token});
      if (response.statusCode == 200) {
        _streamController.add(json.decode(response.body));
      } else {
        _streamController.add("error");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _streamController = StreamController();
    _stream = _streamController.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('English Words'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: TextFormField(
                    onChanged: (String text) {
                      if (_debounce?.isActive ?? false) _debounce.cancel();
                      _debounce = Timer(const Duration(milliseconds: 100), () {
                        _search();
                      });
                    },
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: "Search for a word",
                        contentPadding: const EdgeInsets.only(left: 24.0),
                        border: InputBorder.none),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  _search();
                },
              )
            ],
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(8.0),
        child: StreamBuilder(
          stream: _stream,
          builder: (BuildContext ctx, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Center(
                child: Text("Enter a search word"),
              );
            }
            if (snapshot.data == "waiting") {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data == "error") {
              return Center(
                child: Text(
                  "No such word",
                  style: TextStyle(color: Colors.red, fontSize: 20.0),
                ),
              );
            }
            return ListView.builder(
                itemCount: snapshot.data["definitions"].length,
                itemBuilder: (BuildContext context, int index) {
                  return ListBody(
                    children: [
                      Container(
                        color: Colors.grey[300],
                        child: ListTile(
                          leading: snapshot.data["definitions"][index]
                                      ["image_url"] ==
                                  null
                              ? null
                              : CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    snapshot.data["definitions"][index]
                                        ["image_url"],
                                  ),
                                ),
                          title: Text(_controller.text.trim() +
                              "(" +
                              snapshot.data["definitions"][index]["type"] +
                              ")"),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            snapshot.data["definitions"][index]["definition"]),
                      ),
                    ],
                  );
                });
          },
        ),
      ),
    );
  }
}