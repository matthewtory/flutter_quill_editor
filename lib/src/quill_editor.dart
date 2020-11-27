import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'link_dialog.dart';
import 'constants.dart';

typedef Future<void> QuillEditorMessageHandler(
    BuildContext context, WebViewController webViewController, dynamic payload);
typedef void QuillEditorOpenUrlCallback(String url);

class QuillEditorController extends ValueNotifier<String> {
  final String initialText;

  QuillEditorController({
    this.initialText,
  }) : super(initialText);
}

class QuillEditor extends StatefulWidget {
  static String _editorHtml;
  static String _quillJs;
  static String _quillCss;

  static Future<void> prepare() async {
    if (_editorHtml == null || _quillJs == null || _quillCss == null) {
      List<String> files = await Future.wait([
        rootBundle.loadString(kAssetEditorHtml),
        rootBundle.loadString(kAssetQuillJs),
        rootBundle.loadString(kAssetQuillCssSnow),
      ]);

      _editorHtml = files[0];
      _quillJs = files[1];
      _quillCss = files[2];
    }
  }

  final QuillEditorController controller;
  final VoidCallback onReady;
  final String css;
  final String header;
  final QuillEditorOpenUrlCallback onOpenUrl;
  final Color color;
  final int fontSize;

  QuillEditor(
      {Key key,
      this.controller,
      this.css,
      this.header,
      this.onOpenUrl,
      this.color,
      this.onReady,
      this.fontSize})
      : super(key: key);

  @override
  _QuillEditorState createState() => _QuillEditorState();
}

class _QuillEditorState extends State<QuillEditor> {
  Map<String, QuillEditorMessageHandler> _messageHandlers = {
    'link': (context, controller, payload) async {
      String url =
          await showDialog(context: context, builder: (_) => QuillLinkDialog());

      if (url != null) {
        Map<String, dynamic> data = payload as Map<String, dynamic>;

        int index = data['index'] as int;
        int length = data['length'] as int;

        String javascript;
        if (length > 0) {
          javascript = 'quill.format("link", "$url")';
        } else {
          javascript = 'quill.insertText($index, "$url", "link", "$url")';
        }
        try {
          String result = await controller.evaluateJavascript(javascript);
          print(result);
        } catch (e) {
          print(e);
        }
      }
    }
  };

  Completer<WebViewController> _webViewControllerCompleter =
      Completer<WebViewController>();

  String _localValue;
  bool _didLoadHtml = false;

  @override
  void initState() {
    super.initState();

    widget.controller?.addListener(_controllerChangedValue);
  }

  @override
  void didUpdateWidget(QuillEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_controllerChangedValue);
      widget.controller?.addListener(_controllerChangedValue);
    }

    bool refreshEditor = false;
    if (oldWidget.css != widget.css) {
      refreshEditor = true;
    }
    if (oldWidget.color != widget.color) {
      refreshEditor = true;
    }
    if (oldWidget.fontSize != widget.fontSize) {
      refreshEditor = true;
    }

    if (refreshEditor) {
      _webViewControllerCompleter.future.then((controller) async {
        String url = await _loadUrl(context);
        _didLoadHtml = false;
        controller.loadUrl(url);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: _loadUrl(context),
        builder: (context, snapshot) {
          Widget child;

          if (snapshot.hasData) {
            child = _buildWebView(context, snapshot.data);
          } else {
            child = SizedBox.shrink();
          }

          return child;
        });
  }

  Widget _buildWebView(BuildContext context, String url) {
    return WebView(
      initialUrl: url,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (webViewController) {
        if (!_webViewControllerCompleter.isCompleted) {
          _webViewControllerCompleter.complete(webViewController);
          if (widget.onReady != null) {
            widget.onReady();
          }
        }
      },
      navigationDelegate: (nav) {
        if (!_didLoadHtml) {
          _didLoadHtml = true;

          return NavigationDecision.navigate;
        }

        if (widget.onOpenUrl != null) {
          widget.onOpenUrl(nav.url);
        }

        return NavigationDecision.prevent;
      },
      javascriptChannels: Set.from([
        JavascriptChannel(
            name: 'Flutter',
            onMessageReceived: (JavascriptMessage message) async {
              Map<String, dynamic> data = jsonDecode(message.message);
              WebViewController controller =
                  await _webViewControllerCompleter.future;

              dynamic type = data['type'];
              if (type is String) {
                switch (type) {
                  case 'text_change':
                    _onReceiveTextChanged(data['payload']);
                    break;
                  default:
                    print(type);
                    final handler = _messageHandlers[type];
                    print(handler);
                    if (handler != null) {
                      handler(context, controller, data['payload']);
                    }
                }
              }
            })
      ]),
    );
  }

  Future<String> _loadUrl(
    BuildContext context,
  ) async {
    await QuillEditor.prepare();

    String html = QuillEditor._editorHtml;
    String js = QuillEditor._quillJs;
    String css = QuillEditor._quillCss;

    if (widget.color != null) {
      css = css.replaceAll('#06c',
          'rgba(${widget.color.red}, ${widget.color.green},${widget.color.blue}, ${widget.color.alpha})');
    }

    html = html.replaceAll(
        '{initialText}', _localValue ?? widget.controller?.initialText ?? '');

    html = '<html>'
        '<head>'
        '<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">'
        '<style>$css</style>'
        '<style>.ql-container { ${widget.fontSize != null ? 'font-size: ${widget.fontSize}px' : ''} } </style>'
        '${widget.header ?? ''}'
        '<style>${widget.css ?? ''}</style>'
        '<script>$js</script>'
        '</head>'
        '<body>$html</body>'
        '</html>';

    return Uri.dataFromString(
      html,
      encoding: Encoding.getByName('utf-8'),
      mimeType: 'text/html',
    ).toString();
  }

  void _controllerChangedValue() {
    assert(widget.controller != null);

    if (widget.controller.value != _localValue) {
      _updateValue();
    }
  }

  Future<void> _updateValue() async {
    assert(widget.controller != null);

    _localValue = widget.controller.value;
    WebViewController _controller = await _webViewControllerCompleter.future;

    String value = widget.controller.value.replaceAll('"', "'");
    await _controller.evaluateJavascript(
        '(function(){const delta = quill.clipboard.convert("$value"); quill.setContents(delta, "silent");})()');
  }

  void _onReceiveTextChanged(Map<String, dynamic> payload) {
    dynamic text = payload['text'];
    if (text is String) {
      _localValue = text;
      widget.controller?.value = text;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
