import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:coinverse/const/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

import '../api/api.dart';
import '../main.dart';
import '../models/message.dart';
import '../utils/date_util.dart';
import '../utils/dialogs.dart';

// for showing single message details
class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;
    return InkWell(
        onLongPress: () {
          _showBottomSheet(isMe);
        },
        child: isMe ? _greenMessage() : _blueMessage());
  }

  // sender or another user message
  Widget _blueMessage() {
    //update last read message if sender and receiver are different
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      children: [
        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: mq.height * 0.005,
                horizontal: widget.message.type == Type.image
                    ? mq.width * .03
                    : mq.width * .03),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
                color: AppColor.appPrimaryColor,
                // border: Border.all(color: Colors.lightBlue),
                //making borders curved
                borderRadius: const BorderRadius.only(
                    // topLeft: Radius.circular(20),
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.message.type == Type.text
                    ?
                    //show text
                    Flexible(
                        child: Text(
                          widget.message.msg,
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white),
                        ),
                      )
                    :
                    //show image
                    Flexible(
                        flex: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: widget.message.msg,
                            placeholder: (context, url) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image, size: 70),
                          ),
                        ),
                      ),
                //message time
                Container(
                  margin: EdgeInsets.only(top: mq.width * .06),
                  padding: EdgeInsets.only(left: mq.width * .04),
                  child: Text(
                    MyDateUtil.getFormattedTime(
                        context: context, time: widget.message.sent),
                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // our or user message
  Widget _greenMessage() {
    return Container(
      constraints: BoxConstraints(maxWidth: mq.width / 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          //message content
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: mq.height * 0.005,
                  horizontal: widget.message.type == Type.image
                      ? mq.width * .03
                      : mq.width * .03),
              margin: EdgeInsets.symmetric(
                  horizontal: mq.width * .04, vertical: mq.height * .01),
              decoration: BoxDecoration(
                  color: AppColor.appSecondaryColor,
                  //making borders curved
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      // topRight: Radius.circular(30),
                      bottomRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.message.type == Type.text
                      ?
                      //show text
                      Flexible(
                          child: Text(
                            widget.message.msg,
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.white),
                          ),
                        )
                      :
                      //show image
                      Flexible(
                          flex: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                              // width: mq.height* 0.3,
                              // height: mq.height* 0.3,
                              imageUrl: widget.message.msg,
                              placeholder: (context, url) => const Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.image, size: 70),
                            ),
                          ),
                        ),

                  //message time
                  Container(
                    margin: EdgeInsets.only(top: mq.width * .06),
                    padding: EdgeInsets.only(left: mq.width * .04),
                    child: Row(
                      children: [
                        //sent time
                        Text(
                          MyDateUtil.getFormattedTime(
                              context: context, time: widget.message.sent),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white60),
                        ),
                        //for adding some space
                        const SizedBox(width: 2),
                        //double tick blue icon for message read
                        if (widget.message.read.isNotEmpty)
                          Icon(Icons.done_all_rounded,
                              color: Colors.blue.withAlpha(150), size: 20),
                        //for adding some space
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // bottom sheet for modifying message details
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        backgroundColor: AppColor.appPrimaryColor2,
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              //black divider
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),

              widget.message.type == Type.text
                  ?
                  //copy option
                  _OptionItem(
                      icon: const Icon(Icons.copy_all_rounded,
                          color: Colors.blue, size: 26),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          //for hiding bottom sheet
                          Navigator.pop(context);

                          Dialogs.showSnackbar(context, 'Text Copied!');
                        });
                      })
                  :
                  //save option
                  _OptionItem(
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.blue, size: 26),
                      name: 'Save Image',
                      onTap: () async {
                        try {
                          log('Image Url: ${widget.message.msg}');
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: 'We Chat')
                              .then((success) {
                            //for hiding bottom sheet
                            Navigator.pop(context);
                            if (success != null && success) {
                              Dialogs.showSnackbar(
                                  context, 'Image Successfully Saved!');
                            }
                          });
                        } catch (e) {
                          log('ErrorWhileSavingImg: $e');
                        }
                      }),

              //separator or divider
              if (isMe)
                Divider(
                  color: Colors.black54,
                  endIndent: mq.width * .04,
                  indent: mq.width * .04,
                ),

              //edit option
              if (widget.message.type == Type.text && isMe)
                _OptionItem(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 26),
                    name: 'Edit Message',
                    onTap: () {
                      //for hiding bottom sheet
                      Navigator.pop(context);

                      _showMessageUpdateDialog();
                    }),

              //delete option
              if (isMe)
                _OptionItem(
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.red, size: 26),
                    name: 'Delete Message',
                    onTap: () async {
                      Navigator.pop(context);
                      await APIs.deleteMessage(widget.message).then((value) {
                        //for hiding bottom sheet
                        if (mounted) {
                          log("poping");
                        } else {
                          log('message');
                        }
                      });
                    }),

              //separator or divider
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              //sent time
              _OptionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  name:
                      'Sent At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
                  onTap: () {}),

              //read time
              _OptionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                  name: widget.message.read.isEmpty
                      ? 'Read At: Not seen yet'
                      : 'Read At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }

  //dialog for updating message content
  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.msg;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColor.appPrimaryColor2,
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: Row(
                children: [
                  Icon(
                    Icons.message,
                    color: AppColor.appSecondaryColor,
                    size: 28,
                  ),
                  const Text(
                    ' Update Message',
                    style: TextStyle(color: Colors.white60),
                  )
                ],
              ),

              //content
              content: TextFormField(
                style: const TextStyle(color: Colors.white60),
                initialValue: updatedMsg,
                maxLines: null,
                onChanged: (value) => updatedMsg = value,
                decoration: InputDecoration(
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    )),

                //update button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                      APIs.updateMessage(widget.message, updatedMsg);
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }
}

//custom options card (for copy, edit, delete, etc.)
class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.only(
              left: mq.width * .05,
              top: mq.height * .015,
              bottom: mq.height * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('    $name',
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white60,
                        letterSpacing: 0.5)))
          ]),
        ));
  }
}
