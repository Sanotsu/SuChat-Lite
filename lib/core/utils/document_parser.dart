import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

///
/// 如果像上面把文本读取放在一个函数内，可能出现不同库的一些其他问题，比如
///    2024-07-20 如果上层使用了compute来后台处理，这个插件就会报错：
///      Bad state: The BackgroundIsolateBinaryMessenger.instance value is invalid until
///      BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
/// 所以根据分类，有些用上compute，有些用不上，所以拆开来
///
Future<String> extractTextFromPdf(String path) async {
  final pdfDocument = PdfDocument(inputBytes: File(path).readAsBytesSync());

  // 实测直接获取文档全部内容，可能会挤在一起，单词都无法区分开了
  // String text = PdfTextExtractor(pdfDocument).extractText();

  // 从文档中提取文本行集合
  final textLines = PdfTextExtractor(pdfDocument).extractTextLines();

  var text = "";
  for (var line in textLines) {
    text += line.text;
  }

  pdfDocument.dispose();
  return text;
}
