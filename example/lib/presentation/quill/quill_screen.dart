import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/markdown_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'
    show FlutterQuillEmbeds, QuillSharedExtensionsConfigurations;
import 'package:quill_html_converter/quill_html_converter.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../misc/dialog.dart';
import '../extensions/scaffold_messenger.dart';
import '../shared/widgets/home_screen_button.dart';
import 'my_quill_editor.dart';
import 'my_quill_toolbar.dart';

@immutable
class QuillScreenArgs {
  const QuillScreenArgs({required this.document});

  final Document document;
}

class QuillScreen extends StatefulWidget {
  const QuillScreen({
    required this.args,
    super.key,
  });

  final QuillScreenArgs args;

  static const routeName = '/quill';

  @override
  State<QuillScreen> createState() => _QuillScreenState();
}

class _QuillScreenState extends State<QuillScreen> {
  final _controller = QuillController.basic();
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  var _isReadOnly = false;

  @override
  void initState() {
    super.initState();
    _controller.document = widget.args.document;
  }

  // Future<void> _init() async {
  //   final reader = await ClipboardReader.readClipboard();
  //   if (reader.canProvide(Formats.htmlText)) {
  //     final html = await reader.readValue(Formats.htmlText);
  //     if (html == null) {
  //       return;
  //     }
  //     final delta = DeltaHtmlExt.fromHtml(html);
  //     _controller.document = Document.fromDelta(delta);
  //   }
  // }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaders = <String, List>{
      'JSON': [
        (Delta delta) => JsonEncoder.withIndent('  ').convert(delta.toJson()),
        (String text) => Delta.fromJson(jsonDecode(text)),
        Icons.data_object,
      ],
      'HTML': [
        (Delta delta) => delta.toHtml(),
        (String text) => DeltaX.fromHtml(text),
        Icons.html,
      ],
      'MARKDOWN': [
        (Delta delta) => htmlToMarkdown(delta.toHtml()),
        (String text) => MarkdownToDelta(markdownDocument: mdDocument).convert(text),
        Icons.edit,
      ],
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Quill'),
        actions: [
          ...loaders.entries.map((e) {
            return IconButton(
              tooltip: 'Load with ${e.key}',
              onPressed: () async {
                String? text = e.value[0](_controller.document.toDelta());

                text = await showEditDialog(context, title: 'Load with ${e.key}', content: text);
                if (text == null) return;

                _controller.document =
                    text.isEmpty ? Document() : Document.fromDelta(e.value[1](text));
              },
              icon: Icon(e.value[2]),
            );
          }),
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              final plainText = _controller.document.toPlainText(
                FlutterQuillEmbeds.defaultEditorBuilders(),
              );
              if (plainText.trim().isEmpty) {
                ScaffoldMessenger.of(context).showText(
                  "We can't share empty document, please enter some text first",
                );
                return;
              }
              Share.share(plainText);
            },
            icon: const Icon(Icons.share),
          ),
          const HomeScreenButton(),
        ],
      ),
      body: Column(
        children: [
          if (!_isReadOnly)
            MyQuillToolbar(
              controller: _controller,
              focusNode: _editorFocusNode,
            ),
          Builder(
            builder: (context) {
              return Expanded(
                child: MyQuillEditor(
                  configurations: QuillEditorConfigurations(
                    sharedConfigurations: _sharedConfigurations,
                    controller: _controller,
                    readOnly: _isReadOnly,
                  ),
                  scrollController: _editorScrollController,
                  focusNode: _editorFocusNode,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_isReadOnly ? Icons.lock : Icons.edit),
        onPressed: () => setState(() => _isReadOnly = !_isReadOnly),
      ),
    );
  }

  QuillSharedConfigurations get _sharedConfigurations {
    return const QuillSharedConfigurations(
      // locale: Locale('en'),
      extraConfigurations: {
        QuillSharedExtensionsConfigurations.key: QuillSharedExtensionsConfigurations(
          assetsPrefix: 'assets', // Defaults to assets
        ),
      },
    );
  }
}
