import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share/share.dart';
import 'model/eternal.dart';
import 'model/eternal_response.dart';

void main() {
  // it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();
  runApp(new MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles;
  String _sharedText;
  InAppWebViewController webView;
  String url = "";
  String urlResponse = "";
  double progress = 0;
  ContextMenu contextMenu;
  String urlPost = 'https://eternal.api.dragonchain.com/v1/transaction/';
  final myController = new TextEditingController();
  bool _isButtonDisabled;
  String urlType = "";
  bool isLoading = false;


  //Method to call the API.
  Future<EternalResponse> createPost(Eternal post, String urlType) async {
    final response = await http
        .post(urlPost + urlType, body: {'url': post.url, 'text': post.text});
    if (response.statusCode != 200) throw Exception(response.body);
    return postFromJson(response.body);
  }

  EternalResponse postFromJson(String str) {
    final jsonData = json.decode(str);
    return EternalResponse.fromJson(jsonData);
  }


  //To Show Alert Dialog when there is an Invalid URL or TWEET.
  void _showAlertDialog(BuildContext context) {
    final alert = AlertDialog(
      title: Text("Error"),
      content: Text("There was an error please input a valid URL or Tweet."),
      actions: [
        FlatButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.pop(context);
            })
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _isButtonDisabled = true;
    isLoading = false;
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      setState(() {
        print("Shared:" + (_sharedFiles?.map((f) => f.path)?.join(",") ?? ""));
        _sharedFiles = value;
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
      });
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      _sharedText = value;

      // webView.loadUrl(url: _sharedText);
      if (_sharedText != null && _sharedText.isNotEmpty) {
        setState(() {
          _sharedText = value;
          Eternal eternal = new Eternal();
          eternal.url = _sharedText;
          eternal.text = _sharedText + 'Posted';
          isLoading = true;
          if (_sharedText.contains('twitter')) {
            urlType = 'tweet';
          } else {
            urlType = 'url';
          }
          createPost(eternal, urlType).then((response) {
            urlResponse =
                'https://eternal.report/transaction/' + response.transactionId;
            webView.loadUrl(url: urlResponse);
            _isButtonDisabled = false;
            isLoading = false;
          }).catchError((e) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _showAlertDialog(context));
          });
        });
      }
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      setState(() {
        _sharedText = value;
        if (_sharedText != null && _sharedText.isNotEmpty) {
          Eternal eternal = new Eternal();
          eternal.url = _sharedText;
          eternal.text = _sharedText + 'Posted';
          isLoading = true;
          if (_sharedText.contains('twitter')) {
            urlType = 'tweet';
          } else {
            urlType = 'url';
          }
          createPost(eternal, urlType).then((response) {
            urlResponse =
                'https://eternal.report/transaction/' + response.transactionId;
            webView.loadUrl(url: urlResponse);
            _isButtonDisabled = false;
            isLoading = false;
          }).catchError((e) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _showAlertDialog(context));
          });
        }
        // webView.loadUrl(url: _sharedText);
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyleBold = const TextStyle(fontWeight: FontWeight.normal);
    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/EternalBack.png"),
                  fit: BoxFit.cover,
                ),
                color: Color.fromRGBO(102, 48, 84, 1).withOpacity(1.0),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  color: Colors.white,
                  gradient: LinearGradient(
                      begin: FractionalOffset.bottomCenter,
                      end: FractionalOffset.topCenter,
                      colors: [
                        Colors.grey.withOpacity(0.0),
                        Colors.black,
                      ],
                      stops: [
                        0.0,
                        1.0
                      ])),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Image.asset("assets/images/eternalLogo.png",height: MediaQuery.of(context).size.height * 0.08,
                width:MediaQuery.of(context).size.height * 0.25,),

                Container(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                      "CURRENT URL\n${(url.length > 50) ? url.substring(0, 50) + "..." : url}",style: TextStyle(fontSize : 15,color: Colors.white,fontFamily: "Rubik Bold",
                    fontWeight: FontWeight.normal,
                    ),),
                ),
                isLoading ? CircularProgressIndicator() : Container(),
                Container(
                    padding: EdgeInsets.all(5.0),
                    child: progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container()),
                Container(
                  margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.height * 0.02, 0, MediaQuery.of(context).size.height * 0.02, 0),
                  child: TextField(
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromRGBO(25, 27, 28, 10),
                      hintStyle: TextStyle(fontSize: 20.0, color: Colors.grey,fontFamily: 'Rubik Bold',fontWeight: FontWeight.normal),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      hintText: 'Enter Url or Tweet...',
                      contentPadding:
                      const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(25, 27, 28, 10)),
                        borderRadius: BorderRadius.circular(25.7),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(25, 27, 28, 10)),
                        borderRadius: BorderRadius.circular(25.7),
                      ),
                    ),
                    controller: myController,
                  ),
                ),
                //SizedBox(height: MediaQuery.of(context).size.height * 0.01,),
                RaisedButton(
                  color : Color.fromRGBO(20, 121, 183, 1),
                  onPressed: () {
                    setState(() {
                      if (myController.text != null && myController.text.isNotEmpty) {
                        Eternal eternal = new Eternal();
                        eternal.url = myController.text;
                        eternal.text = myController.text + 'Posted';
                        isLoading = true;
                        if (myController.text.contains('twitter')) {
                          urlType = 'tweet';
                        } else {
                          urlType = 'url';
                        }
                        createPost(eternal, urlType).then((response) {
                          urlResponse =
                              'https://eternal.report/transaction/' + response.transactionId;
                          webView.loadUrl(url: urlResponse);
                          _isButtonDisabled = false;
                          isLoading = false;
                        }).catchError((e) {
                          _showAlertDialog(context);
                          setState(() {
                            isLoading = false;
                          });
                        });
                      }
                     // webView.loadUrl(url: myController.text.toString());
                    });
                  },
                  child: Text("Submit",style: TextStyle(color: Colors.white,fontFamily: 'Rubik Bold',fontWeight: FontWeight.normal),),
                ),
              //  SizedBox(height: MediaQuery.of(context).size.height * 0.01,),
                Text("SHARED URL or TEXT", style: TextStyle(color: Colors.white,fontFamily: "Rubik Bold",
                  fontWeight: FontWeight.normal,
                ),),
               // SizedBox(height: 20,),
                Container(
                  margin: EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
                  child: Text(_sharedText ?? "", style: TextStyle(color: Colors.white,fontFamily: "Rubik Bold",
                  fontWeight: FontWeight.normal,
                  ),),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.height * 0.55,
                  child: Container(
                    margin: EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(
                        const Radius.circular(10),
                      ),
                      child: InAppWebView(
                        initialUrl: "https://www.google.com/",
                        initialHeaders: {},
                        initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                          debuggingEnabled: true,
                        )),
                        onWebViewCreated: (InAppWebViewController controller) {
                          webView = controller;
                        },
                        onLoadStart:
                            (InAppWebViewController controller, String url) {
                          setState(() {
                            this.url = url;
                          });
                        },
                        onLoadStop: (InAppWebViewController controller,
                            String url) async {
                          setState(() {
                            this.url = url;
                          });
                        },
                        onProgressChanged:
                            (InAppWebViewController controller, int progress) {
                          setState(() {
                            this.progress = progress / 100;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                      color : Color.fromRGBO(20, 121, 183, 1),
                      child: Icon(Icons.refresh),
                      onPressed: () {
                        if (webView != null) {
                          webView.reload();
                        }
                      },
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RaisedButton(
                      color : Colors.blueAccent,
                      child: Text(_isButtonDisabled ? "Hold on..." : "Share",style: TextStyle(color: Colors.white,fontFamily: 'Rubik Bold',fontWeight: FontWeight.normal),),
                      onPressed: _isButtonDisabled
                          ? null
                          : () async {
                              urlResponse.isEmpty
                                  ? ""
                                  : await Share.share(urlResponse);
                            }),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
