import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:coinverse/const/constants.dart';
import 'package:coinverse/screens/view_user_profile.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:upi_india/upi_india.dart';
import 'package:upi_india/upi_response.dart';

import '../api/api.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../utils/date_util.dart';
import '../widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all messages
  List<Message> _list = [];

  //upi payment variables
  Future<UpiResponse>? _transaction;
  final UpiIndia _upiIndia = UpiIndia();
  List<UpiApp>? apps;
  String amount = '';
  String senderName = "";

  //for handling message text changes
  final _textController = TextEditingController();

  //showEmoji -- for storing value of showing or hiding emoji
  //isUploading -- for checking if image is uploading or not?
  bool _showEmoji = false, _isUploading = false;

  @override
  void initState() {
    _upiIndia.getAllUpiApps(mandatoryTransactionId: false).then((value) {
      setState(() {
        apps = value;
      });
    }).catchError((e) {
      print(e);
      apps = [];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          //if emojis are shown & back button is pressed then hide emojis
          //or else simple close current screen on back button click
          onWillPop: () {
            if (_showEmoji) {
              setState(() => _showEmoji = !_showEmoji);
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            //app bar
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),

            backgroundColor: AppColor.appPrimaryColor2,

            //body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list = data
                                  ?.map((e) => Message.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                reverse: true,
                                itemCount: _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: _list[index]);
                                });
                          } else {
                            return const Center(
                              child: Text('Say Hii! 👋',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
                      }
                    },
                  ),
                ),

                //progress indicator for showing uploading
                if (_isUploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          child: CircularProgressIndicator(strokeWidth: 2))),

                //chat input filed
                _chatInput(),

                //show emojis on keyboard emoji button click & vice versa
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      config: Config(
                        bgColor: const Color.fromARGB(255, 234, 248, 255),
                        columns: 8,
                        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // app bar widget
  Widget _appBar() {
    return Material(
      color: AppColor.appPrimaryColor,
      child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ViewProfileScreen(user: widget.user)));
          },
          child: StreamBuilder(
              stream: APIs.getUserInfo(widget.user),
              builder: (context, snapshot) {
                final data = snapshot.data?.docs;
                final list =
                    data?.map((e) => ChatUser.fromJson(e.data())).toList() ??
                        [];
                senderName = list.isNotEmpty ? list[0].name : widget.user.name;
                return Row(
                  children: [
                    //back button
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white)),

                    //user profile picture
                    ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * .03),
                      child: CachedNetworkImage(
                        width: mq.height * .05,
                        height: mq.height * .05,
                        imageUrl:
                            list.isNotEmpty ? list[0].image : widget.user.image,
                        errorWidget: (context, url, error) =>
                            const CircleAvatar(
                                child: Icon(CupertinoIcons.person)),
                      ),
                    ),

                    //for adding some space
                    const SizedBox(width: 10),

                    //user name & last seen time
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //user name
                        Text(list.isNotEmpty ? list[0].name : widget.user.name,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),

                        //for adding some space
                        const SizedBox(height: 2),

                        //last seen time of user
                        Text(
                            list.isNotEmpty
                                ? list[0].isOnline
                                    ? 'Online'
                                    : MyDateUtil.getLastActiveTime(
                                        context: context,
                                        lastActive: list[0].lastActive)
                                : MyDateUtil.getLastActiveTime(
                                    context: context,
                                    lastActive: widget.user.lastActive),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white60)),
                      ],
                    ),
                    Expanded(
                        child: Padding(
                      padding: EdgeInsets.only(right: mq.width * 0.02),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () {
                            _showPaymentDialog();
                          },
                          icon: Icon(
                            Icons.currency_rupee_rounded,
                            color: AppColor.appSecondaryColor,
                          ),
                        ),
                      ),
                    ))
                  ],
                );
              })),
    );
  }

  // bottom chat input field
  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          //input field & buttons
          Expanded(
            child: Card(
              color: AppColor.appPrimaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: Icon(Icons.emoji_emotions,
                          color: AppColor.appWhiteColor.withAlpha(95),
                          size: 25)),

                  Expanded(
                      child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                    },
                    decoration: InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(
                            color: AppColor.appWhiteColor.withAlpha(95)),
                        border: InputBorder.none),
                    style: const TextStyle(color: Colors.white),
                  )),

                  //pick image from gallery button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Picking multiple images
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);

                        // uploading & sending image one by one
                        for (var i in images) {
                          log('Image Path: ${i.path}');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: Icon(Icons.image,
                          color: AppColor.appWhiteColor.withAlpha(95),
                          size: 26)),

                  //take image from camera button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() => _isUploading = true);

                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: Icon(Icons.camera_alt_rounded,
                          color: AppColor.appWhiteColor.withAlpha(95),
                          size: 26)),

                  //adding some space
                  SizedBox(width: mq.width * .02),
                ],
              ),
            ),
          ),

          //send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  //on first message (add user to my_user collection of chat user)
                  APIs.sendFirstMessage(
                      widget.user, _textController.text, Type.text);
                } else {
                  //simply send message
                  APIs.sendMessage(
                      widget.user, _textController.text, Type.text);
                }
                _textController.text = '';
              }
            },
            minWidth: 0,
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            color: AppColor.appSecondaryColor,
            child: const Icon(Icons.send, color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }

  //display upi apps
  Widget _displayUpiApps() {
    if (apps == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (apps!.isEmpty) {
      return const Center(
        child: Text("No Apps Found To Handle Transaction"),
      );
    } else {
      return Container(
        constraints: BoxConstraints(
          maxHeight: mq.height * 0.3,
        ),
        // color: Colors.yellow,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Wrap(
              children: apps!.map<Widget>((UpiApp app) {
                return GestureDetector(
                  onTap: () {
                    _transaction = initiateTransaction(app);
                    // Navigator.pop(context);
                    // _upiDetail();
                  },
                  child: Container(
                    // color: Colors.red,
                    height: 100,
                    width: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.memory(
                          app.icon,
                          height: 60,
                          width: 60,
                        ),
                        Padding(
                          padding: EdgeInsets.all(mq.height * 0.01),
                          child: Text(app.name, style: const TextStyle(color: Colors.white60),),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
  }



  //initiate transaction
  Future<UpiResponse> initiateTransaction(UpiApp app) async {
    return _upiIndia.startTransaction(
        app: app,
        receiverUpiId: "rv995854@okicici",
        receiverName: senderName,
        transactionRefId: "transactionRefId",
        amount: 1,
    );
  }
  //display tranx data
  Widget displayTransactionData(title, body) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title: "),
          Flexible(
              child: Text(
                body,
              )),
        ],
      ),
    );
  }
  //handeling upi error
  String _upiErrorHandler(error) {
    switch (error) {
      case UpiIndiaAppNotInstalledException:
        return 'Requested app not installed on device';
      case UpiIndiaUserCancelledException:
        return 'You cancelled the transaction';
      case UpiIndiaNullResponseException:
        return 'Requested app didn\'t return any response';
      case UpiIndiaInvalidParametersException:
        return 'Requested app cannot handle the transaction';
      default:
        return 'An Unknown error has occurred';
    }
  }
  //checking transaction status
  void _checkTxnStatus(String status) {
    switch (status) {
      case UpiPaymentStatus.SUCCESS:
        print('Transaction Successful');
        break;
      case UpiPaymentStatus.SUBMITTED:
        print('Transaction Submitted');
        break;
      case UpiPaymentStatus.FAILURE:
        print('Transaction Failed');
        break;
      default:
        print('Received an Unknown transaction status');
    }
  }
  //all upi apps
  void _upiApps(){
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          backgroundColor: AppColor.appPrimaryColor2,
          contentPadding: const EdgeInsets.only(
              left: 24, right: 24, top: 20, bottom: 10),

          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.currency_rupee_rounded,
                color: AppColor.appSecondaryColor,
                size: 20,
              ),
              const Text(
                '  Choose The Upi App',
                style: TextStyle(color: Colors.white60, fontSize: 18),
              ),
            ],
          ),
          content: _displayUpiApps(),

        ),
    );
  }

  //display transaction data
  void _upiDetail(){
    showDialog(context: context, builder: (_) => AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      backgroundColor: AppColor.appPrimaryColor2,
      contentPadding: const EdgeInsets.only(
          left: 24, right: 24, top: 20, bottom: 10),

      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.currency_rupee_rounded,
            color: AppColor.appSecondaryColor,
            size: 20,
          ),
          const Text(
            '  Choose The Upi App',
            style: TextStyle(color: Colors.white60, fontSize: 18),
          ),
        ],
      ),
      content: FutureBuilder(
        future: _transaction,
        builder: (BuildContext context, AsyncSnapshot<UpiResponse> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  _upiErrorHandler(snapshot.error.runtimeType),
                  style: TextStyle(
                    color: Colors.white60
                  ),
                ), // Print's text message on screen
              );
            }

            // If we have data then definitely we will have UpiResponse.
            // It cannot be null
            UpiResponse _upiResponse = snapshot.data!;

            // Data in UpiResponse can be null. Check before printing
            String txnId = _upiResponse.transactionId ?? 'N/A';
            String resCode = _upiResponse.responseCode ?? 'N/A';
            String txnRef = _upiResponse.transactionRefId ?? 'N/A';
            String status = _upiResponse.status ?? 'N/A';
            String approvalRef = _upiResponse.approvalRefNo ?? 'N/A';
            _checkTxnStatus(status);

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  displayTransactionData('Transaction Id', txnId),
                  displayTransactionData('Response Code', resCode),
                  displayTransactionData('Reference Id', txnRef),
                  displayTransactionData('Status', status.toUpperCase()),
                  displayTransactionData('Approval No', approvalRef),
                ],
              ),
            );
          } else
            return Center(
              child: Text(''),
            );
        },
      )
    ));
  }

  //dialog for entering payment amount
  void _showPaymentDialog() {
    String? updatedMsg;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              actionsAlignment: MainAxisAlignment.center,
              backgroundColor: AppColor.appPrimaryColor2,
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.currency_rupee_rounded,
                    color: AppColor.appSecondaryColor,
                    size: 20,
                  ),
                  const Text(
                    '  Enter The Amount',
                    style: TextStyle(color: Colors.white60, fontSize: 18),
                  ),
                ],
              ),
              //content
              content: TextFormField(
                style: const TextStyle(color: Colors.white, fontSize: 48),
                maxLines: 1,
                onChanged: (value) => updatedMsg = value,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(right: 50),
                  prefixIcon: Icon(
                    Icons.currency_rupee_rounded,
                    color: AppColor.appSecondaryColor,
                    size: 20,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.transparent), // Bottom border color
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors
                            .transparent), // Bottom border color when focused
                  ),
                  alignLabelWithHint: true,
                  hintText: '0.00',
                  hintStyle: TextStyle(
                      color: Colors.white60
                          .withAlpha(90)), // Style for the hint text
                  // contentPadding: const EdgeInsets.only(bottom: 0),
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
              ),
              //actions
              actions: [
                //cancel button
                MaterialButton(
                    padding: EdgeInsets.only(top: mq.height * 0.05),
                    onPressed: () {
                      //hide alert dialog
                      setState(() {
                        amount = updatedMsg!;
                      });
                      Navigator.pop(context);
                      _upiApps();
                    },
                    child: Text(
                      'Next',
                      style: TextStyle(
                          color: AppColor.appSecondaryColor, fontSize: 16),
                    )),
              ],
            ));
  }
}
