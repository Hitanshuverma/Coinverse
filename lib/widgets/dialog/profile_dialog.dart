import 'package:cached_network_image/cached_network_image.dart';
import 'package:coinverse/const/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/chat_user.dart';
import '../../screens/view_user_profile.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: AppColor.appPrimaryColor.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
          width: mq.width * .6,
          height: mq.height * .35,
          child: Stack(
            children: [
              // here for stories
              //user profile picture
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: mq.height * 0.04),
                  child: Center(
                    child: ClipRRect(

                      borderRadius: BorderRadius.circular(mq.height * .25),
                      child: CachedNetworkImage(
                        width: mq.width * .5,
                        height: mq.width * .52,
                        fit: BoxFit.cover,
                        imageUrl: user.image,
                        errorWidget: (context, url, error) =>
                            const CircleAvatar(child: Icon(CupertinoIcons.person)),
                      ),
                    ),
                  ),
                ),
              ),

              //user name
              Positioned(
                left: mq.width * .04,
                top: mq.height * .02,
                width: mq.width * .55,
                child: Text(user.name,
                    style: const TextStyle(
                      color: Colors.white60,
                        fontSize: 18, fontWeight: FontWeight.w500)),
              ),

              //info button
              Positioned(
                  right: 8,
                  top: 6,
                  child: MaterialButton(
                    onPressed: () {
                      //for hiding image dialog
                      Navigator.pop(context);

                      //move to view profile screen
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ViewProfileScreen(user: user)));
                    },
                    minWidth: 0,
                    padding: const EdgeInsets.all(0),
                    shape: const CircleBorder(),
                    child: Icon(Icons.info_outline,
                        color: AppColor.appSecondaryColor, size: 30),
                  ))
            ],
          )),
    );
  }
}
