import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

enum Status  {Unauthenticated , Authenticated, Authenticating, Uninitialized}

class AuthenticatorClass with  ChangeNotifier{
  Status _status = Status.Uninitialized;
  FirebaseAuth _auth;
  User? _user;
  var imageURICurr=null;
  final theSavedWords = <String>{};
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseStorage _storage = FirebaseStorage.instance;

  AuthenticatorClass.instance() : _auth = FirebaseAuth.instance{
    _auth.authStateChanges().listen(_authStatusChange);
    _user = _auth.currentUser;
    _authStatusChange(_user);
  }

  Future<void> _authStatusChange(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
      _user = null;
    } else {
      _status = Status.Authenticated;
      _user = firebaseUser;
    }
    notifyListeners();
  }

  User? get user => _user;
  Status get status => _status;
  bool get isAuthenticated => Status.Authenticated == _status;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
    }
    catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      try {
        imageURICurr = await _storage.ref('images').child(user!.email!).getDownloadURL();
      }catch(e){
        imageURICurr=null;
      }
      notifyListeners();
      return true;
    }
    catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  //Future<void> uploadImage(File file) async{
    //await _storage.ref('images').child(_user!.uid).putFile(file);
    //notifyListeners();
  //}
  //Future<String> downloadImage() async{
    //try {
      //return await _storage.ref('images').child(_user!.uid).getDownloadURL();
    //} on Exception catch(e){
      //return "https://firebasestorage.googleapis.com/v0/b/hellome-7d8cb.appspot.com/o/images%2Fno-profile-picture.png?alt=media&token=2e30255e-a76f-4802-b4e8-2ae6bd6fba44";
    //}

  //}


  Future<void> signOut() async {
    _auth.signOut();
    theSavedWords.clear();
    imageURICurr=null;
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> deletePair(String pair) async {
    theSavedWords.remove(pair);
    notifyListeners();
    updateDB();
  }

  Future<void> updateDB() async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.email).set({
        "wordPairs": theSavedWords.toList(),
      });
    }
  }

  Future<void> updateImgURI(String? key,String image)async{
    imageURICurr=await _storage.ref('images').child(key!).putFile(File(image)).then((file) => file.ref.getDownloadURL());
    notifyListeners();
  }

  Future<void> addNewPair(String pair) async {
    theSavedWords.add(pair);
    notifyListeners();
    updateDB();
  }

  Future<void> updateWords()async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.email).get().then((snapshot) {
        if (snapshot.exists) {
          theSavedWords.addAll(snapshot.data()!['wordPairs'].cast<String>());
        }
        updateDB();
        notifyListeners();
      });
    }
  }
}