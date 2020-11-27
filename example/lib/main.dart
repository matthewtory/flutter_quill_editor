import 'package:flutter/material.dart';
import 'package:flutter_quill_editor/flutter_quill_editor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  QuillEditorController _controller;

  @override
  void initState() {
    super.initState();

    _controller = QuillEditorController(initialText: '<h1>Hello</h1>');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Quill'),
        ),
        body: QuillEditor(
          controller: _controller,
          css:
              '.ql-container {font-family: Raleway,Helvetica, Arial, sans-serif; letter-spacing: -0.07px;  font-size: 14px; }'
              'a {word-break: break-all; color: rgb(225, 45, 114) !important}'
              'a span {color: rgb(225, 45, 114) !important}'
              'h1 { font-weight: 700; letter-spacing: -0.14px; color: #3e1368}'
              'h2 { font-weight: 700; letter-spacing: -0.14px; color: #3e1368}'
              'h3 { font-weight: 700; letter-spacing: -0.14px; color: #3e1368}'
              'h4 { font-weight: 700; letter-spacing: -0.14px; color: #3e1368}',
          header:
              '<link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Raleway:400,700">',
          onOpenUrl: (url) => print('tried to open $url'),
          color: Colors.green.shade700,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _controller.value = '<h1>hello</h1>',
          child: Icon(Icons.edit),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
