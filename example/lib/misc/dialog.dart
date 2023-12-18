import 'package:flutter/material.dart';

Future<String?> showEditDialog(
  BuildContext context, {
  String? title,
  String? content,
}) async {
  var controller = TextEditingController(text: content);
  content = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title == null ? null : Text(title),
        insetPadding: EdgeInsets.all(20),
        contentPadding: EdgeInsets.all(10),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(5),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: Text('ok'),
          )
        ],
      );
    },
  );
  return content;
}
