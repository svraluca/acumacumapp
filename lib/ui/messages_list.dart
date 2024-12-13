import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/chatScreen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';

import 'message_model.dart';

class MessageList extends StatefulWidget {
  final bool showBackButton;
  const MessageList({super.key, this.showBackButton = true});

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late String currentName, currentProfile;
  late Stream messageListStream;
  late String spliteId2;

  List<Message> messagess = [];
  List<String> msgIds = [];
  late List<String> msgNames = [];
  late List<String> msgUrls = [];
  HashMap<String, Message> lastMsg = HashMap();
  late Message eachMessage;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  CollectionReference messageColl =
      FirebaseFirestore.instance.collection('ChatRoom');
  late String currentId;
  late String otherUserId;
  late String otherUserName;
  late String otherAvatarUrl;
  late String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _resetUnreadCounter();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    userId = _firebaseAuth.currentUser!.uid;
    
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        var userData = userDoc.data() as Map<String, dynamic>;
        
        setState(() {
          currentName = userData['name'] ?? ''; // Provide default empty string
          currentId = userDoc.id;
          currentProfile = userData['avatarUrl'] ?? ''; // Provide default empty string
        });
        
        // Only call retrieveMessageList if we have the required data
        if (currentName.isNotEmpty) {
          retrieveMessageList();
        } else {
          print('Warning: User name is empty');
        }
      } else {
        print('Warning: User document does not exist or component unmounted');
      }
    } catch (e) {
      print('Error in didChangeDependencies: $e');
      // Optionally show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading user data. Please try again.'),
          ),
        );
      }
    }
  }

  // This is the trick!
  void _reset() {
    Navigator.pushAndRemoveUntil(
      context,
      NoTransitionRoute(
        builder: (context) => NoAnimationPageWrapper(
          child: Homepage(currentIndex: 4),
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFDA291C),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          leading: widget.showBackButton ? IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop({'currentIndex': 0});
            },
          ) : null,
          title: Text(
            'Mesaje',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.0,
              letterSpacing: -1.0,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: Colors.white),
              onPressed: _reset,
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : lastMsg.isNotEmpty
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: ListView.builder(
                          itemCount: lastMsg.length,
                          itemBuilder: (context, int index) {
                            otherUserId = msgIds[index];
                            print("List item $index : $otherUserId");
                            otherUserName = msgNames[index];
                            otherAvatarUrl = msgUrls[index];
                            print(
                                "current otheruserid: $otherUserId length of msgs: ${lastMsg.length}\n${lastMsg.keys}");
                            eachMessage = lastMsg[otherUserId]!;
                            return GestureDetector(
                              onTap: () async {
                                // Mark messages as read before navigating
                                await markMessagesAsRead(otherUserId);
                                
                                // Navigate to chat screen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      serviceProviderId: msgIds[index],
                                      userName: msgNames[index],
                                      avatarUrl: msgUrls[index],
                                      price: 'N/A',
                                    ),
                                  ),
                                );

                                // After returning from chat, refresh the message list
                                retrieveMessageList();
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                    color: Colors.white,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            const CircleAvatar(
                                              radius: 28.0,
                                              backgroundImage: AssetImage(
                                                  'assets/images/profilepic.png'),
                                            ),
                                            const SizedBox(width: 16.0),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  otherUserName,
                                                  style: const TextStyle(
                                                      fontSize: 15.0,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87),
                                                ),
                                                const SizedBox(height: 8.0),
                                                if (eachMessage.isBookingOffer)
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 8.0),  // Add space after badge
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 3.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange,
                                                      borderRadius: BorderRadius.circular(4.0),
                                                    ),
                                                    child: const Text(
                                                      'Booking Offer',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11.0,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                Container(
                                                  width: MediaQuery.of(context).size.width * 0.35,
                                                  child: RichText(
                                                    overflow: TextOverflow.ellipsis,
                                                    strutStyle: const StrutStyle(fontSize: 13.0),
                                                    text: TextSpan(
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13.0,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                      text: eachMessage.message.isNotEmpty 
                                                          ? eachMessage.message 
                                                          : 'Booking request sent/received', // Default message for booking requests
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4.0),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.25,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 8.0),
                                                      child: Text(
                                                        _formatMessageTime(eachMessage.time.toDate()),
                                                        style: const TextStyle(
                                                          fontSize: 12.0,
                                                          color: Colors.grey,
                                                          fontWeight: FontWeight.w400
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(
                                                      Icons.more_vert,
                                                      color: Colors.grey,
                                                      size: 20,
                                                    ),
                                                    elevation: 3,
                                                    color: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    onSelected: (String choice) async {
                                                      if (choice == 'Delete') {
                                                        // Show confirmation dialog
                                                        bool? confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return AlertDialog(
                                                              backgroundColor: Colors.white,  // White background
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(15),
                                                              ),
                                                              title: const Text(
                                                                'Delete Chat',
                                                                style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.black87,
                                                                ),
                                                              ),
                                                              content: const Text(
                                                                'Are you sure you want to delete this chat?',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors.black87,
                                                                ),
                                                              ),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  child: const Text(
                                                                    'Cancel',
                                                                    style: TextStyle(
                                                                      color: Colors.black87,
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop(false);
                                                                  },
                                                                ),
                                                                TextButton(
                                                                  child: const Text(
                                                                    'Delete',
                                                                    style: TextStyle(
                                                                      color: Colors.red,
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop(true);
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );

                                                        if (confirm == true) {
                                                          try {
                                                            // Get the exact chat room ID from the current item
                                                            String chatRoomId = '$currentName&$otherUserName';  // Using names instead of IDs
                                                            String reverseChatRoomId = '$otherUserName&$currentName';

                                                            print('Attempting to delete chat:');
                                                            print('Current name: $currentName');
                                                            print('Other user name: $otherUserName');
                                                            print('Trying chatRoomId: $chatRoomId');
                                                            print('Trying reverseChatRoomId: $reverseChatRoomId');

                                                            // First, check if either chat room exists
                                                            var chatRoomSnapshot = await FirebaseFirestore.instance
                                                                .collection('ChatRoom')
                                                                .where(FieldPath.documentId, whereIn: [chatRoomId, reverseChatRoomId])
                                                                .get();

                                                            if (chatRoomSnapshot.docs.isNotEmpty) {
                                                              var chatRoom = chatRoomSnapshot.docs.first;
                                                              print('Found chat room with ID: ${chatRoom.id}');

                                                              // Delete all messages in the chat
                                                              var messages = await chatRoom.reference
                                                                  .collection('chats')
                                                                  .get();
                                                              
                                                              print('Deleting ${messages.docs.length} messages');
                                                              
                                                              // Delete messages first
                                                              for (var message in messages.docs) {
                                                                await message.reference.delete();
                                                              }

                                                              // Then delete the chat room
                                                              await chatRoom.reference.delete();
                                                              print('Chat room deleted successfully');

                                                              // Show success message
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text('Chat deleted successfully'),
                                                                  duration: Duration(seconds: 2),
                                                                ),
                                                              );

                                                              // Refresh the message list
                                                              setState(() {
                                                                msgIds.removeAt(index);
                                                                msgNames.removeAt(index);
                                                                msgUrls.removeAt(index);
                                                                messagess.removeAt(index);
                                                                lastMsg.remove(otherUserId);
                                                              });
                                                            } else {
                                                              print('No chat room found. Checking all chat rooms:');
                                                              var allChatRooms = await FirebaseFirestore.instance
                                                                  .collection('ChatRoom')
                                                                  .get();
                                                              
                                                              print('Available chat rooms:');
                                                              for (var room in allChatRooms.docs) {
                                                                print('Room ID: ${room.id}');
                                                              }
                                                              
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text('Chat room not found'),
                                                                  duration: Duration(seconds: 2),
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            print('Error deleting chat: $e');
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('Error deleting chat: $e'),
                                                                duration: const Duration(seconds: 2),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                    itemBuilder: (BuildContext context) {
                                                      return ['Delete'].map((String choice) {
                                                        return PopupMenuItem<String>(
                                                          value: choice,
                                                          child: Text(
                                                            choice,
                                                            style: const TextStyle(
                                                              color: Colors.black87,
                                                              fontSize: 14.0,
                                                              fontWeight: FontWeight.w400,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: Color(0xFFEEEEEE),
                                  ),
                                ],
                              ),
                            );
                          }),
                    )
                  : const Center(
                      child: Text('Nu aveti nicio conversatie activa'),
                    ),
        ),
      ),
    );
  }

  retrieveMessageList() async {
    setState(() {
      _isLoading = true;
      msgIds = [];
      messagess = [];
      lastMsg.clear();
      msgNames = [];
      msgUrls = [];
    });
    
    try {
      print('Debug - Current user details:');
      print('Current user ID: $userId');
      print('Current user name: $currentName');
      
      FirebaseFirestore.instance
          .collection('ChatRoom')
          .snapshots()
          .listen((chatRoomsSnapshot) async {
        if (!mounted) return;

        setState(() {
          msgIds = [];
          messagess = [];
          lastMsg.clear();
          msgNames = [];
          msgUrls = [];
        });

        var userRooms = chatRoomsSnapshot.docs.where((doc) {
          String roomId = doc.id;
          print('Debug - Checking room ID: $roomId');
          
          // Check all possible formats
          bool containsUser = false;
          
          // Check ID format with underscore
          if (roomId.contains('_')) {
            List<String> ids = roomId.split('_');
            containsUser = ids.contains(userId);
            print('Debug - Checking underscore format: $ids contains $userId = $containsUser');
          } 
          // Check name format with ampersand
          else if (roomId.contains('&')) {
            List<String> names = roomId.split('&');
            containsUser = names.contains(currentName) || 
                          names.contains(currentName.trim());
            print('Debug - Checking ampersand format: $names contains $currentName = $containsUser');
          }
          
          print('Debug - Final result for room $roomId contains user: $containsUser');
          return containsUser;
        }).toList();

        print('Debug - Found ${userRooms.length} rooms for current user');

        for (var room in userRooms) {
          try {
            print('Debug - Processing room: ${room.id}');
            
            var messages = await room.reference
                .collection('chats')
                .orderBy('time', descending: true)
                .get();

            if (messages.docs.isNotEmpty) {
              var lastMessage = messages.docs.first.data();
              String senderId = lastMessage['senderId'] ?? '';
              String receiverId = lastMessage['receiverId'] ?? '';
              String messageType = lastMessage['type'] ?? '';
              
              print('Debug - Message details:');
              print('Room ID: ${room.id}');
              print('Sender ID: $senderId');
              print('Receiver ID: $receiverId');
              print('Message Type: $messageType');

              String otherUserId;
              if (room.id.contains('_')) {
                // For ID format
                List<String> ids = room.id.split('_');
                otherUserId = ids[0] == userId ? ids[1] : ids[0];
              } else {
                // For name format
                List<String> names = room.id.split('&');
                String otherName = names[0] == currentName ? names[1] : names[0];
                
                // Get user ID from name
                var userQuery = await FirebaseFirestore.instance
                    .collection('Users')
                    .where('name', isEqualTo: otherName.trim())
                    .get();
                    
                if (userQuery.docs.isNotEmpty) {
                  otherUserId = userQuery.docs.first.id;
                } else {
                  // Fallback to message sender/receiver
                  otherUserId = senderId == userId ? receiverId : senderId;
                }
              }

              print('Debug - Other user ID: $otherUserId');

              if (otherUserId.isNotEmpty) {
                Message messageObj = Message(
                  message: lastMessage['message'] ?? '',
                  time: lastMessage['time'],
                  unread: false,
                  senderId: senderId,
                  isBookingOffer: messageType == 'booking_offer',
                );

                // Fetch other user's details
                var userDoc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(otherUserId)
                    .get();

                if (userDoc.exists && mounted) {
                  String otherUserName = userDoc.data()?['name'] ?? '';
                  String otherUserAvatar = userDoc.data()?['avatarUrl'] ?? '';
                  
                  print('Debug - Other user details:');
                  print('Name: $otherUserName');
                  print('Avatar: $otherUserAvatar');

                  setState(() {
                    if (!msgIds.contains(otherUserId)) {
                      msgIds.add(otherUserId);
                      msgNames.add(otherUserName);
                      msgUrls.add(otherUserAvatar);
                      lastMsg[otherUserId] = messageObj;
                      messagess.add(messageObj);
                    } else {
                      // Update existing message if newer
                      int existingIndex = msgIds.indexOf(otherUserId);
                      DateTime existingTime = lastMsg[otherUserId]!.time.toDate();
                      DateTime newTime = lastMessage['time'].toDate();
                      
                      if (newTime.isAfter(existingTime)) {
                        lastMsg[otherUserId] = messageObj;
                        messagess[existingIndex] = messageObj;
                      }
                    }
                  });
                }
              }

              // Add this check for unread messages
              if (receiverId == userId && 
                  !(lastMessage['read'] ?? false)) {
                // Update the user's unread status
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .update({
                      'hasUnreadMessages': true,
                      'unreadMessages': FieldValue.increment(1)
                    });
              }
            }
          } catch (e) {
            print('Error processing room ${room.id}: $e');
          }
        }

        // After all messages are collected, sort them by time (newest first)
        if (mounted && lastMsg.isNotEmpty) {
          setState(() {
            // Create a list of indices and sort them based on message times
            List<int> sortedIndices = List.generate(msgIds.length, (i) => i);
            sortedIndices.sort((a, b) {
              DateTime timeA = lastMsg[msgIds[a]]!.time.toDate();
              DateTime timeB = lastMsg[msgIds[b]]!.time.toDate();
              return timeB.compareTo(timeA); // Changed to sort newest first
            });

            // Create new sorted lists
            List<String> sortedMsgIds = sortedIndices.map((i) => msgIds[i]).toList();
            List<String> sortedMsgNames = sortedIndices.map((i) => msgNames[i]).toList();
            List<String> sortedMsgUrls = sortedIndices.map((i) => msgUrls[i]).toList();
            List<Message> sortedMessages = sortedIndices.map((i) => messagess[i]).toList();

            // Update the lists with sorted data
            msgIds = sortedMsgIds;
            msgNames = sortedMsgNames;
            msgUrls = sortedMsgUrls;
            messagess = sortedMessages;
          });
        }

        setState(() {
          _isLoading = false;
        });
      });

    } catch (e, stackTrace) {
      print('Error in retrieveMessageList: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatMessageTime(DateTime messageTime) {
    DateTime now = DateTime.now().toLocal();
    messageTime = messageTime.toLocal();
    
    final difference = now.difference(messageTime);
    
    // Add more granular time differences and debug info
    print('Formatting time - Message: $messageTime, Now: $now');
    print('Difference in minutes: ${difference.inMinutes}');
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      // For messages less than a day old, show exact hours and minutes
      return '${difference.inHours}h ${difference.inMinutes % 60}m ago';
    } else if (difference.inDays < 7) {
      return '${_getDayName(messageTime)} ${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      switch (date.weekday) {
        case 1: return 'Mon';
        case 2: return 'Tue';
        case 3: return 'Wed';
        case 4: return 'Thu';
        case 5: return 'Fri';
        case 6: return 'Sat';
        case 7: return 'Sun';
        default: return '';
      }
    }
  }

  // Add this new method to mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      print('Starting markMessagesAsRead for chat with: $otherUserId');
      String chatRoomId = '$currentName&$otherUserName';
      String reverseChatRoomId = '$otherUserName&$currentName';

      var chatRoomSnapshot = await FirebaseFirestore.instance
          .collection('ChatRoom')
          .where(FieldPath.documentId, whereIn: [chatRoomId, reverseChatRoomId])
          .get();

      if (chatRoomSnapshot.docs.isNotEmpty) {
        var chatRoom = chatRoomSnapshot.docs.first;
        
        // Only mark messages as read where current user is the RECEIVER
        var unreadMessages = await chatRoom.reference
            .collection('chats')
            .where('receiverId', isEqualTo: userId)  // Only messages where current user is receiver
            .where('unread', isEqualTo: true)
            .get();

        print('Found ${unreadMessages.docs.length} unread messages for current user');

        // Update unread status for these messages
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'unread': false});
        }
        await batch.commit();

        // Immediately update current user's unread status
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .update({
              'unreadMessages': 0,
              'hasUnreadMessages': false
            });
        print('Reset unread status for user: $userId');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Add this method to check if the current user has any unread messages
  Future<bool> hasUnreadMessages() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      
      return (userDoc.data()?['hasUnreadMessages'] == true) || 
             ((userDoc.data()?['unreadMessages'] ?? 0) > 0);
    } catch (e) {
      print('Error checking unread messages: $e');
      return false;
    }
  }

  Future<void> _resetUnreadCounter() async {
    if (userId.isEmpty) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({
            'unreadMessages': 0,
            'hasUnreadMessages': false
          });
      print('Reset unread counter for user: $userId');
    } catch (e) {
      print('Error resetting unread counter: $e');
    }
  }

  @override
  void dispose() {
    _resetUnreadCounter();
    super.dispose();
  }
}

class NoAnimationPageWrapper extends StatelessWidget {
  final Widget child;
  
  const NoAnimationPageWrapper({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class NoAnimationRoute extends PageRouteBuilder {
  final Widget Function(BuildContext) builder;

  NoAnimationRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
}

class NoTransitionRoute<T> extends MaterialPageRoute<T> {
  NoTransitionRoute({ 
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
    builder: builder,
    settings: settings,
    maintainState: false,
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  bool get opaque => true;
}

Stream<bool> getUnreadMessageStatus() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    print('No user ID available for unread message status');
    return Stream.value(false);
  }

  print('Starting unread message status stream for user: $userId');
  
  return FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return false;
        
        final data = snapshot.data() as Map<String, dynamic>;
        final hasUnread = data['hasUnreadMessages'] ?? false;
        final unreadCount = data['unreadMessages'] ?? 0;
        
        print('Current user unread status:');
        print('User ID: $userId');
        print('hasUnreadMessages: $hasUnread');
        print('unreadMessages count: $unreadCount');
        
        return hasUnread || unreadCount > 0;
      });
}

