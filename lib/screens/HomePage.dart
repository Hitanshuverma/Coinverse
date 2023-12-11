import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coinverse/const/constants.dart';
import 'package:coinverse/screens/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../utils/dialogs.dart';
import '../widgets/chat_card.dart';

//home screen -- where all available contacts are shown
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> _list = [];

  // for storing searched items
  final List<ChatUser> _searchList = [];
  // for storing search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard when a tap is detected on screen
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        //if search is on & back button is pressed then close search
        //or else simple close current screen on back button click
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          backgroundColor: AppColor.appPrimaryColor,
          //app bar
          appBar: AppBar(
            backgroundColor: AppColor.appPrimaryColor,
            // backgroundColor: Colors.red,
            title: _isSearching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Name, Email, ...',hintStyle: const TextStyle(fontSize: 17, letterSpacing: 0.5,color: Colors.white, fontFamily: 'Montserrat'),),
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, letterSpacing: 0.5,color: Colors.white, fontFamily: 'Montserrat'),
                    //when search text changes then updated search list
                    onChanged: (val) {
                      //search logic
                      _searchList.clear();

                      for (var i in _list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          _searchList.add(i);
                          setState(() {
                            _searchList;
                          });
                        }
                      }
                    },
                  )
                : const Text(
                    'Messages',
                    style: TextStyle(
                        fontFamily: 'Quicksand',
                        letterSpacing: 1.5,
                        fontSize: 25,
                        color: Colors.white),
                  ),
            actions: [
              //search user button
              IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                    });
                  },
                  icon: Icon(
                    _isSearching
                        ? CupertinoIcons.clear_circled_solid
                        : Icons.search,
                    color: Colors.white,
                  )),

              //more features button
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(user: APIs.me)));
                },
                icon: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .03),
                  child: CachedNetworkImage(
                    width: mq.height * .040,
                    height: mq.height * .040,
                    imageUrl: APIs.me.image,
                    errorWidget: (context, url, error) => const CircleAvatar(
                        child: Icon(CupertinoIcons.person)),
                  ),
                ),
              )
            ],
          ),

          //floating button to add new user
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              backgroundColor: AppColor.appSecondaryColor,
                onPressed: () {
                  _addChatUserDialog();
                },
                child: const Icon(Icons.add_comment_rounded)),
          ),

          //body
          body: Column(
            children: [
              Container(
                width: mq.width,
                // color: Colors.red,
                padding: EdgeInsets.fromLTRB(mq.width * 0.04, 0, 0, 2),
                child: Text(
                  'RECENT',
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      letterSpacing: 3,
                      color: Colors.white60),
                ),
              ),
              Container(
                // color: Colors.green,
                height: mq.height * 0.02,
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColor.appPrimaryColor2,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: EdgeInsets.only(top: 25),
                  // color: Colors.red,
                  child: StreamBuilder(
                    stream: APIs.getMyUsersId(),
                    // stream: APIs.firestore.collection('users').snapshots(),
                    //get id of only known users
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(child: CircularProgressIndicator());

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          return StreamBuilder(
                            stream: APIs.getAllUsers(
                                snapshot.data?.docs.map((e) => e.id).toList() ??
                                    []),

                            //get only those user, who's ids are provided
                            builder: (context, snapshot) {
                              switch (snapshot.connectionState) {
                                //if data is loading
                                case ConnectionState.waiting:
                                case ConnectionState.none:
                                // return const Center(
                                //     child: CircularProgressIndicator());

                                //if some or all data is loaded then show it
                                case ConnectionState.active:
                                case ConnectionState.done:
                                  final data = snapshot.data?.docs;
                                  _list = data
                                          ?.map((e) => ChatUser.fromJson(e.data()))
                                          .toList() ??
                                      [];

                                  if (_list.isNotEmpty) {
                                    return ListView.builder(
                                        scrollDirection: Axis.vertical,
                                        shrinkWrap: true,
                                        itemCount: _isSearching
                                            ? _searchList.length
                                            : _list.length,
                                        padding:
                                            EdgeInsets.only(top: mq.height * .01),
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return ChatUserCard(
                                              user: _isSearching
                                                  ? _searchList[index]
                                                  : _list[index]);
                                        });
                                  } else {
                                    //no chats
                                    return const Center(
                                      child: Text('No Connections Found!',
                                          style: TextStyle(fontSize: 20, letterSpacing: 0.5,color: Colors.white, fontFamily: 'Montserrat'),),
                                    );
                                  }
                              }
                            },
                          );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // for adding new chat user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColor.appPrimaryColor,
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: AppColor.appSecondaryColor,
                    size: 28,
                  ),
                  const Text('  Add User', style: TextStyle(letterSpacing: 0.5,color: Colors.white, fontFamily: 'Quicksand'),),
                ],
              ),

              //content
              content: TextFormField(
                style: const TextStyle(letterSpacing: 0.5,color: Colors.white, fontFamily: 'Montserrat'),
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    hintText: 'Email Id',
                    hintStyle: const TextStyle(letterSpacing: 0.5,color: Colors.white, fontFamily: 'Montserrat'),
                    prefixIcon: Icon(Icons.email, color: AppColor.appSecondaryColor),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 16, letterSpacing: 0.5,color: Colors.white, fontFamily: 'Quicksand'),)),

                //add button
                MaterialButton(
                    onPressed: () async {
                      //hide alert dialog
                      Navigator.pop(context);
                      if (email.isNotEmpty) {
                        await APIs.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackbar(
                                context, 'User does not Exists!');
                          }
                        });
                      }
                    },
                    child: const Text(
                      'Add',
                      style: const TextStyle(fontSize: 16, letterSpacing: 0.5,color: Colors.white, fontFamily: 'Quicksand'),
                    ))
              ],
            ));
  }
}
