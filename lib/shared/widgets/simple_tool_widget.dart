import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/utils/screen_helper.dart';
import '../services/network_service.dart';

// 绘制转圈圈
Widget buildLoader(bool isLoading) {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  } else {
    return Container();
  }
}

void commonHintDialog(
  BuildContext context,
  String title,
  String message, {
  double? msgFontSize,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: TextStyle(fontSize: msgFontSize ?? 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

Future<void> commonMarkdwonHintDialog(
  BuildContext context,
  String title,
  String message, {
  double? msgFontSize,
}) async {
  unfocusHandle();
  // 强行停200毫秒(100还不够)，密码键盘未收起来就显示弹窗出现布局溢出的问题
  // 上面直接的commonHintDialog没问题，这里主要是MarkdownBody的问题
  await Future.delayed(const Duration(milliseconds: 200));

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (context) {
      // 获取屏幕尺寸
      final size = MediaQuery.of(context).size;
      // 计算显示最大宽度
      final maxWidth = ScreenHelper.isDesktop() ? size.width * 0.6 : size.width;

      return AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: message,
              selectable: true,
              // 设置Markdown文本全局样式
              styleSheet: MarkdownStyleSheet(
                // 普通段落文本颜色(假定用户输入就是普通段落文本)
                p: TextStyle(fontSize: msgFontSize, color: Colors.black),
                // ... 其他级别的标题样式
                // 可以继续添加更多Markdown元素的样式
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

// 异常弹窗
void commonExceptionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(message, style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

/// 通用的底部信息弹窗
void commonMDHintModalBottomSheet(
  BuildContext context,
  String title,
  String message, {
  double? msgFontSize,
}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        // height: MediaQuery.of(context).size.height / 4 * 3,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 18)),
                  TextButton(
                    child: const Text('关闭'),
                    onPressed: () {
                      Navigator.pop(context);
                      unfocusHandle();
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 2, thickness: 2),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: MarkdownBody(
                    data: message,
                    selectable: true,
                    // 设置Markdown文本全局样式
                    styleSheet: MarkdownStyleSheet(
                      // 普通段落文本颜色(假定用户输入就是普通段落文本)
                      p: TextStyle(fontSize: msgFontSize, color: Colors.black),
                      // ... 其他级别的标题样式
                      // 可以继续添加更多Markdown元素的样式
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// 显示底部提示条(默认都是出错或者提示的)
void showSnackMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor = Colors.red,
  int? seconds,
}) {
  var snackBar = SnackBar(
    content: Text(message),
    duration: Duration(seconds: seconds ?? 3),
    backgroundColor: backgroundColor,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// 生成随机颜色
Color genRandomColor() => Color(
  (math.Random().nextDouble() * 0xFFFFFF).toInt(),
).withValues(alpha: 1.0);

// 生成随机颜色带透明度
Color genRandomColorWithOpacity({double? opacity}) => Color(
  (math.Random().nextDouble() * 0xFFFFFF).toInt(),
).withValues(alpha: opacity ?? math.Random().nextDouble());

// 指定长度的随机字符串
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
math.Random _rnd = math.Random();
String getRandomString(int length) {
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

// 指定长度的范围的随机字符串(包含上面那个，最大最小同一个值即可)
String generateRandomString(int minLength, int maxLength) {
  int length = minLength + _rnd.nextInt(maxLength - minLength + 1);

  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

///
/// form builder 库中文本栏位和下拉选择框组件的二次封装
///
// 构建表单的文本输入框
Widget cusFormBuilerTextField(
  String name, {
  String? initialValue,
  double? valueFontSize,
  int? maxLines,
  String? hintText, // 可不传提示语
  TextStyle? hintStyle,
  String? labelText, // 可不传栏位标签，在输入框前面有就行
  String? Function(Object?)? validator,
  bool? isOutline = false, // 输入框是否有线条
  bool isReadOnly = false, // 输入框是否有只读
  TextInputType? keyboardType,
  void Function(String?)? onChanged,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Padding(
    padding: EdgeInsets.all(5),
    child: FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      maxLines: maxLines,
      readOnly: isReadOnly,
      style: TextStyle(fontSize: valueFontSize),
      // 2023-12-04 没有传默认使用name，原本默认的.text会弹安全键盘，可能无法输入中文
      // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
      // 注意：如果有最大行超过1的话，默认启用多行的键盘类型
      enableSuggestions: true,
      keyboardType:
          keyboardType ??
          ((maxLines != null && maxLines > 1)
              ? TextInputType.multiline
              : TextInputType.text),

      decoration: _buildInputDecoration(
        isOutline,
        isReadOnly,
        labelText,
        hintText,
        hintStyle,
      ),
      validator: validator,
      onChanged: onChanged,
      // 输入的格式限制
      inputFormatters: inputFormatters,
    ),
  );
}

// formbuilder 下拉框和文本输入框的样式等内容
InputDecoration _buildInputDecoration(
  bool? isOutline,
  bool isReadOnly,
  String? labelText,
  String? hintText,
  TextStyle? hintStyle,
) {
  final contentPadding = isOutline != null && isOutline
      ? EdgeInsets.symmetric(horizontal: 5, vertical: 15)
      : EdgeInsets.symmetric(horizontal: 5, vertical: 5);

  return InputDecoration(
    isDense: true,
    labelText: labelText,
    hintText: hintText,
    hintStyle: hintStyle,
    contentPadding: contentPadding,
    border: isOutline != null && isOutline
        ? OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))
        : isReadOnly
        ? InputBorder.none
        : null,
    // 设置透明底色
    filled: true,
    fillColor: Colors.transparent,
  );
}

Chip buildSmallChip(String labelText, {Color? bgColor, double? labelTextSize}) {
  return Chip(
    label: Text(labelText),
    backgroundColor: bgColor,
    labelStyle: TextStyle(fontSize: labelTextSize),
    labelPadding: EdgeInsets.zero,
    // 设置负数会报错，但好像看到有点效果呢
    // labelPadding: EdgeInsets.fromLTRB(0, -6, 0, -6),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

// 用一个按钮假装是一个标签，用来展示
Widget buildSmallButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
  void Function()? onPressed,
}) {
  return RawMaterialButton(
    onPressed: onPressed,
    constraints: const BoxConstraints(),
    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    fillColor: bgColor ?? Colors.grey[300],
    child: Text(labelText, style: TextStyle(fontSize: labelTextSize ?? 12)),
  );
}

// 一般当做标签用，比上面个还小
// 传入的字体最好不超过10
SizedBox buildTinyButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return SizedBox(
    // 传入大于12的字体，修正为12；不传则默认12
    height:
        ((labelTextSize != null && labelTextSize > 10)
            ? 10
            : labelTextSize ?? 10) +
        10,
    child: RawMaterialButton(
      onPressed: () {},
      constraints: const BoxConstraints(),
      padding: EdgeInsets.fromLTRB(4, 2, 4, 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      fillColor: bgColor ?? Colors.grey[300],
      child: Text(
        labelText,
        style: TextStyle(
          // 传入大于10的字体，修正为10；不传则默认10
          fontSize: (labelTextSize != null && labelTextSize > 10)
              ? 10
              : labelTextSize ?? 10,
        ),
      ),
    ),
  );
}

// 带有横线滚动条的datatable
Scrollbar buildDataTableWithHorizontalScrollbar({
  required ScrollController scrollController,
  required List<DataColumn> columns,
  required List<DataRow> rows,
}) {
  return Scrollbar(
    thickness: 5,
    // 设置交互模式后，滚动条和手势滚动方向才一致
    interactive: true,
    radius: Radius.circular(5),
    // 不设置这个，滚动条默认不显示，在滚动时才显示
    thumbVisibility: true,
    // trackVisibility: true,
    // 滚动条默认在右边，要改在左边就配合Transform进行修改(此例没必要)
    // 刻意预留一点空间给滚动条
    controller: scrollController,
    child: SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: DataTable(
        // dataRowHeight: 10,
        dataRowMinHeight: 60, // 设置行高范围
        dataRowMaxHeight: 100,
        headingRowHeight: 25, // 设置表头行高
        horizontalMargin: 10, // 设置水平边距
        columnSpacing: 20, // 设置列间距
        columns: columns,
        rows: rows,
      ),
    ),
  );
}

/// ----
///

// 2024-03-12 根据图片地址前缀来区分是否是网络图片
bool isNetworkImageUrl(String imageUrl) {
  return (imageUrl.startsWith('http') || imageUrl.startsWith('https'));
}

/// 强制收起键盘
void unfocusHandle() {
  // 这个不一定有用，比如下面原本键盘弹出来了，跳到历史记录页面，回来之后还是弹出来的
  // FocusScope.of(context).unfocus();

  FocusManager.instance.primaryFocus?.unfocus();
}

/// 构建弹出菜单按钮的条目
PopupMenuItem<String> buildCusPopupMenuItem(
  BuildContext context,
  String value, // 用于判断的值
  String label, // 用于显示的标签文字
  IconData icon, // 图标数据
) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        SizedBox(width: 5),
        Text(label, style: TextStyle(color: Theme.of(context).primaryColor)),
      ],
    ),
  );
}

/// 一些功能按钮的样式统一一下
ButtonStyle buildFunctionButtonStyle({Color? backgroundColor}) {
  return ElevatedButton.styleFrom(
    minimumSize: Size(80, 32),
    padding: EdgeInsets.symmetric(horizontal: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    foregroundColor: Colors.white,
    backgroundColor: backgroundColor ?? Colors.blue,
  );
}

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // 自定义颜色
          ),
          SizedBox(height: 10.0),
          Text('Loading...', style: TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}

// 上方图标下方文字的InkWell按钮
Widget buildIconTextInkWell({
  required IconData icon,
  required String label,
  required VoidCallback? onTap,
  required BuildContext context,
}) {
  var iconColor = Theme.of(context).colorScheme.primary;
  var textColor = Theme.of(context).colorScheme.onSurface;

  return Tooltip(
    message: label,
    verticalOffset: 10,
    preferBelow: false,
    // 此处不在InkWell外面加这个Material会报错
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: onTap == null ? Colors.grey : iconColor,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: onTap == null ? Colors.grey : textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// 上方图标下方文字的TextButton按钮
Widget buildIconWithTextButton({
  required IconData icon,
  required String label,
  required VoidCallback? onTap,
  required BuildContext context,
}) {
  var iconColor = Theme.of(context).colorScheme.primary;
  var textColor = Theme.of(context).colorScheme.onSurface;

  return Tooltip(
    message: label,
    verticalOffset: 20,
    preferBelow: false,
    child: TextButton(
      onPressed: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: onTap == null ? Colors.grey : iconColor,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: onTap == null ? Colors.grey : textColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 构建浮动按钮
Widget buildFloatingActionButton(
  void Function()? onPressed,
  BuildContext context, {
  required IconData icon,
  required String tooltip,
}) {
  return FloatingActionButton(
    onPressed: onPressed,
    tooltip: tooltip,
    shape: const CircleBorder(),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    child: Icon(icon),
  );
}

/// 构建页面上action位置的使用说明按钮
Widget buildInfoButtonOnAction(BuildContext context, String note) {
  return IconButton(
    onPressed: () {
      commonMDHintModalBottomSheet(context, "说明", note, msgFontSize: 15);
    },
    icon: const Icon(Icons.info_outline),
  );
}

/// 没有网的时候，点击就显示弹窗；有网才跳转到功能页面
void showNoNetworkOrGoTargetPage(
  BuildContext context,
  Widget targetPage, {
  Function(dynamic)? thenFunc,
}) async {
  bool isNetworkAvailable = await NetworkStatusService().isNetwork();

  if (!context.mounted) return;
  isNetworkAvailable
      ? Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        ).then((value) => thenFunc?.call(value))
      : commonHintDialog(context, "提示", "请联网后使用该功能。", msgFontSize: 15);
}
