import 'package:html2md/html2md.dart' as html2md;
import 'package:markdown/markdown.dart';

String htmlToMarkdown(String html) {
  final rules = [
    html2md.Rule('image', filters: ['img'], replacement: (content, node) {
      node.asElement()?.attributes.remove('class');
      //Later we can convert this to delta along with the attributes by GoodInlineHtmlSyntax
      return node.outerHTML;
    }),
  ];

  final markdown = html2md.convert(html, rules: rules).replaceAll('unsafe:', '');

  return markdown;
}

Document get mdDocument {
  return Document(
    encodeHtml: false,
    inlineSyntaxes: inlineSyntaxes,
  );
}

Iterable<InlineSyntax>? _inlineSyntaxes;

Iterable<InlineSyntax> get inlineSyntaxes {
  return _inlineSyntaxes ??= [
    GoodInlineHtmlSyntax(),
  ];
}

/// Convert the html to Element, not Text
class GoodInlineHtmlSyntax extends InlineHtmlSyntax {
  @override
  bool tryMatch(InlineParser parser, [int? startMatchPos]) {
    return super.tryMatch(parser, startMatchPos);
  }

  @override
  bool onMatch(parser, match) {
    if (super.onMatch(parser, match)) {
      return true;
    }

    var root = html2md.Node.root(match.group(0)!);
    root = root.childNodes().last.firstChild!;

    final node = Element.empty(root.nodeName);
    final attrs = root.asElement()?.attributes.map((key, value) => MapEntry(key.toString(), value));
    if (attrs != null) node.attributes.addAll(attrs);

    parser.addNode(node);
    parser.start = parser.pos;
    return false;
  }
}
