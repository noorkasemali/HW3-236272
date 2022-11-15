import 'dart:ui';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'authentication.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_)=>AuthenticatorClass.instance(),
      child: MaterialApp(
        title: 'Startup Name Generator',
        theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const RandomWords(),
          '/login': (context) => const WLoginS(),
          '/favorite': (context) => const RandomWords(),
        },
        //home: const RandomWords(),
      ));
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18);
  final _snappingSheetController = SnappingSheetController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          IconButton(
            icon: Icon(Provider.of<AuthenticatorClass>(context,listen:true).isAuthenticated ?
            Icons.exit_to_app : Icons.login),
            onPressed:
            Provider.of<AuthenticatorClass>(context,listen:true).isAuthenticated ? _logout : _addLoginScreen,
            tooltip: Provider.of<AuthenticatorClass>(context,listen:true).isAuthenticated ? 'Logout': 'Login',
          ),
        ],
      ),
      body:Provider.of<AuthenticatorClass>(context,listen:true).isAuthenticated ?
      SnappingSheet(
        controller: _snappingSheetController,
        grabbingHeight: 50,
        grabbing: Container(color: Colors.grey,
          child: ListTile(
            title: Text("Welcome Back, ${Provider.of<AuthenticatorClass>(context,listen: true).user!.email!}",
              style: const TextStyle(fontSize: 17),
            ),
            trailing: const Icon(Icons.keyboard_arrow_up),
            onTap: () => setState(() {
              if(_snappingSheetController.currentPosition==25.0){
                _snappingSheetController.setSnappingSheetPosition(150.0);
              }else{
                _snappingSheetController.setSnappingSheetPosition(25.0);
              }
            }),
          ),
        ),
        sheetBelow: SnappingSheetContent(
            child:Container(color: Colors.white,
              child: Card(
                child: Row(
                  children: [
                    Expanded(
                      //padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 99,
                        height: 99,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: Provider.of<AuthenticatorClass>(context,listen: true).imageURICurr==null
                                ? const DecorationImage(image : AssetImage('images/no_photo.png'))
                                : DecorationImage(image:NetworkImage(Provider.of<AuthenticatorClass>(context,listen: true).imageURICurr))
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text.rich(TextSpan(
                            text: Provider.of<AuthenticatorClass>(context,listen: true).user!.email,
                            style: const TextStyle(fontSize: 16,),
                          )),
                        ),
                        SizedBox(
                          height: 40,
                          width: 140,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.lightBlue,
                              onPrimary: Colors.white,
                            ),
                            onPressed: ()async{
                              FilePickerResult? fileRes = await FilePicker.platform.pickFiles();
                              if (fileRes == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No image selected"),duration: Duration(seconds: 2)));
                              }else{
                                Provider.of<AuthenticatorClass>(context,listen: false).
                                updateImgURI(Provider.of<AuthenticatorClass>(context,listen: false).user!.email,
                                    fileRes.files.single.path!
                                );
                              }
                            },
                            child: const Text('Change avatar'),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
        ),
        child: _widBuild(),
      ): _widBuild(),
    );
  }

  Widget _widBuild() {
    return ListView.builder(
        padding: const EdgeInsets.all(18.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider();
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _widBuildCont(_suggestions[index].asPascalCase);
        }
    );
  }

  Widget _widBuildCont(String pair) {
    final alreadySaved = Provider.of<AuthenticatorClass>(context,listen:false).theSavedWords.contains(pair);
    return ListTile(
      title: Text(
        pair,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.red : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            Provider.of<AuthenticatorClass>(context,listen: false).deletePair(pair);
          } else {
            Provider.of<AuthenticatorClass>(context,listen: false).addNewPair(pair);
          }
        });
      },
    );
  }

  void _addLoginScreen(){
    Navigator.pushNamed(context, '/login');
  }

  void _logout()async{
    await Provider.of<AuthenticatorClass>(context,listen:false).signOut();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully logged out")));
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = Provider.of<AuthenticatorClass>(context,listen: false).theSavedWords.map(
                  (pair) {
                return Dismissible(
                  confirmDismiss: (DismissDirection direction)async{
                    return showDialog(context: context, builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Delete Suggestion"),
                        content: Text("Are you sure you want to delete "+pair+" from your saved suggestions?"),
                        actions: [
                          TextButton(onPressed: () {  Provider.of<AuthenticatorClass>(context,listen: false).deletePair(pair);
                          Navigator.of(context).pop(true);},child: const Text("Yes")),
                          TextButton(onPressed: () { Navigator.of(context).pop();},child: const Text("No")),
                        ],
                      );
                    });
                  },
                  key: ValueKey(pair),
                  background: Container(padding: EdgeInsets.only(left: 18.0),
                    alignment: Alignment.centerLeft,
                    color: Colors.deepPurple,
                    child: Row(children: [Icon(Icons.delete,color: Colors.white),Text('Delete Suggestion',style: TextStyle(color: Colors.white,fontSize: 18))]),
                  )
                  ,child: ListTile(
                  title: Text(
                    pair,
                    style: _biggerFont,
                  ),
                ),
                );
              }
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
              : <Widget>[];
          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }
}

class WLoginS extends StatefulWidget {
  const WLoginS({Key? key}) : super(key: key);

  @override
  State<WLoginS> createState() => _WLoginSState();
}

class _WLoginSState extends State<WLoginS> {
  final TextEditingController _email = TextEditingController(text:"");
  final TextEditingController _password = TextEditingController(text:"");
  final TextEditingController _passValidCont = TextEditingController(text:"");     //passwordValidationController
  bool passValidMatch = true;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthenticatorClass>(context,listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(
          color: Colors.white, //change your color here
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: <Widget>[
          const Padding(
              padding: EdgeInsets.all(5.5),
              child: (Text(
                'Welcome to Startup Names Generator, please log in!',
                style: TextStyle(fontSize: 18,),
              ))),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email',
            ),
          ),
          const SizedBox(height: 26),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
          ),
          const SizedBox(height: 10),
          Provider.of<AuthenticatorClass>(context,listen: true).status == Status.Authenticating
              ? const Center(
                  child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  backgroundColor: Colors.deepPurple,
                  strokeWidth: 2,
                ))
              : SizedBox(
                  width: 360,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: Colors.deepPurple,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0))),
                    onPressed: () async {
                      if (await user.signIn(_email.text, _password.text)) {
                        user.updateWords();
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content:
                              Text("There was an error logging into the app"),
                        ));
                      }
                    },
                    child: const Text(
                      'Log in',
                    ),
                  ),
                ),
          SizedBox(
            width: 360,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: Colors.lightBlue,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0))),
              onPressed: () async {
                setState(() {
                  passValidMatch = true;
                });
                return showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return StatefulBuilder(
                        builder: (BuildContext context, setState) => Container(
                              color: Colors.white,
                              padding: MediaQuery.of(context).viewInsets,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const ListTile(
                                    title: Center(
                                        child: Text('Please confirm your password below:')),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: TextFormField(
                                        obscureText: true,
                                        controller: _passValidCont,
                                        decoration: InputDecoration(
                                          errorText: passValidMatch ? null : "Passwords must match",
                                          labelText: "Password",
                                        )),
                                  ),
                                  SizedBox(
                                    height: 55,
                                    width: 120,
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.lightBlue,
                                            onPrimary: Colors.white,
                                          ),
                                          onPressed: () async {
                                            setState(() {
                                              passValidMatch = _passValidCont.text == _password.text;
                                            });
                                            if (passValidMatch) {
                                              if (await Provider.of<AuthenticatorClass>(context, listen: false)
                                                  .signUp(_email.text, _password.text) != null) {
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              }
                                            }else{
                                              setState((){
                                                _passValidCont.text = '';
                                              });
                                            }
                                          },
                                          child: const Text('Confirm')),
                                    ),
                                  ),
                                ],
                              ),
                            ));
                  },
                );
              },
              child: const Text('New user? Click to sign up',),
          ),
          ),
        ],
      ),
    );
  }
}


