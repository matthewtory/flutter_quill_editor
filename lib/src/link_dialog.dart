import 'package:flutter/material.dart';

class QuillLinkDialog extends StatefulWidget {
  @override
  _QuillLinkDialogState createState() => _QuillLinkDialogState();
}

class _QuillLinkDialogState extends State<QuillLinkDialog> {
  TextEditingController _urlController;
  String _error;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('Add an Link'),
      contentPadding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
      children: [
        TextField(
            decoration: InputDecoration(
                labelText: 'Link URL',
                hintText: 'https://...',
                errorText: _error),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
            controller: _urlController),
        Divider(color: Colors.transparent),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel')),
            FlatButton(
              child: Text('Add'),
              onPressed: () {
                Uri uri = Uri.tryParse(_urlController.text);
                if (uri?.scheme == 'http' || uri?.scheme == 'https') {
                  Navigator.of(context).pop(_urlController.text);
                } else {
                  setState(() => _error = 'Enter a valid URL');
                }
              },
            )
          ],
        )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();

    _urlController.dispose();
  }
}
