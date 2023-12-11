import 'package:cached_network_image/cached_network_image.dart';
import 'package:coinverse/const/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../utils/date_util.dart';

//view profile screen -- to view profile of user
class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColor.appPrimaryColor2,
        //app bar
          appBar: AppBar(title: Text(widget.user.name,style: TextStyle(color: Colors.white60),),backgroundColor: AppColor.appPrimaryColor2,),
          floatingActionButton: //user about
          Material(
            color: AppColor.appPrimaryColor2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Joined On: ',
                  style: TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                      fontSize: 15),
                ),
                Text(
                    MyDateUtil.getLastMessageTime(
                        context: context,
                        time: widget.user.createdAt,
                        showYear: true),
                    style: const TextStyle(color: Colors.white60, fontSize: 15)),
              ],
            ),
          ),

          //body
          body: Container(
            color: AppColor.appPrimaryColor2,
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // for adding some space
                  SizedBox(width: mq.width, height: mq.height * .03),

                  //user profile picture
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .1),
                    child: CachedNetworkImage(
                      width: mq.height * .2,
                      height: mq.height * .2,
                      fit: BoxFit.cover,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),

                  // for adding some space
                  SizedBox(height: mq.height * .03),

                  // user email label
                  Text(widget.user.email,
                      style:
                      const TextStyle(color: Colors.white60, fontSize: 16)),

                  // for adding some space
                  SizedBox(height: mq.height * .02),

                  //user about
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'About: ',
                        style: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                            fontSize: 15),
                      ),
                      Text(widget.user.about,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
