import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login_Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to NoteEngine',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: const Color.fromARGB(255, 123, 117, 117),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                ),
                onPressed: () async {
                  bool success = await FirebaseServices().signInWithGoogle();

                  if (success) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.go('/home');
                    }); // add delay so ui is build

                    await Future.delayed(Duration(milliseconds: 1200));

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Welcome")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Login Failed"),
                        backgroundColor: const Color.fromARGB(255, 230, 67, 67),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset("assets/sign_in.png", height: 35),

                    SizedBox(width: 10),
                    Text("Sign in With Google"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    ;
  }
}

class FirebaseServices {
  final auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> signInWithGoogle() async {
    try {
      writeData();
      readData();

      await googleSignIn.signOut(); // so it doesnt use last acc logged always
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        return false;
      }
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(
        authCredential,
      );
      final User? user = userCredential.user;

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // not null ? then access  isNewUser
        await _firestore.collection('user').doc(user!.uid).set({
          'uid': user.uid,
          'email': user.email,
          'Name': user.displayName,
          'CreatedAt': Timestamp.now(),
        }); // should be map so we use : fullcolon
      }

      return true;
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      return false;
    }
  }

  void writeData() async {
    await _firestore.collection('student').add({
      'Name': 'Devanandh',
      'Job': 'Developer',
      'skill': 'Flutter ',
    });
  }

  void readData() async {
    QuerySnapshot snapshot = await _firestore.collection('student').get();

    for (var doc in snapshot.docs) {
      print(doc.data());
      print(doc['name']);
      print(doc.id);
    }
  }
}
// intent filter can only have 1 elemnt 