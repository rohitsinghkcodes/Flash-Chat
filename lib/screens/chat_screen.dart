import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireStore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for clearing the typed msg after sending
  final messageTextController = TextEditingController();

  final _auth = FirebaseAuth.instance;

  String msgText;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  //To check weather the user is signed in
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  //To retrieve the messages from the firestore using Streams
  void messagesStreams() async {
    await for (var snapshots in _fireStore.collection('messages').snapshots()) {
      for (var message in snapshots.documents) {
        print(message.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Center(
          child: Text(
            '⚡️Chat',
          ),
        ),
        backgroundColor: Colors.blue[900],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        msgText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //for clearing the text field
                      if(msgText!=null)
                        {
                          //Implement send functionality.
                          _fireStore.collection('messages').add({
                            'text': msgText,
                            'sender': loggedInUser.email,
                          });
                        }
                      messageTextController.clear();
                      msgText=null;
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blue[900],
            ),
          );
        }
        final messages = snapshot.data.docs;
        List<MsgBubble> messageBubbles = [];
        for (var msg in messages) {
          final messageText = msg.data()['text'];
          final messageSender = msg.data()['sender'];

          final currUser = loggedInUser.email;

          final messageBubble = MsgBubble(
            text: messageText,
            sender: messageSender,
            isCurUser: currUser == messageSender,
          );

          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MsgBubble extends StatelessWidget {
  MsgBubble(
      {@required this.text, @required this.sender, @required this.isCurUser});
  final String text;
  final String sender;
  final bool isCurUser;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isCurUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12.0,
            ),

          ),
          SizedBox(height: 2.0,),
          Material(
            elevation: 5.0,
            borderRadius: isCurUser ? BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30)) : BorderRadius.only(
                topRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30)),
            color: isCurUser ? Colors.blueAccent[700] : Colors.grey[850],
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
