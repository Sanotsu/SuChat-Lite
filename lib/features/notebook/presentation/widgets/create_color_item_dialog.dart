import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../shared/widgets/toast_utils.dart';

class CreateColorItemDialog extends StatefulWidget {
  final String title;
  final String itemName;
  final int maxLength;
  final Function(String name, int color) onSubmit;

  const CreateColorItemDialog({
    super.key,
    required this.title,
    required this.itemName,
    required this.maxLength,
    required this.onSubmit,
  });

  @override
  State<CreateColorItemDialog> createState() => _CreateColorItemDialogState();
}

class _CreateColorItemDialogState extends State<CreateColorItemDialog> {
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  int? selectedColor;
  bool _showAdvancedPicker = false;
  Color _pickerColor = Colors.blue;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(labelText: '${widget.itemName}名称'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入${widget.itemName}名称';
              }
              if (value.length > widget.maxLength) {
                return '${widget.itemName}名称最多${widget.maxLength}个字';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('选择颜色'),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedPicker = !_showAdvancedPicker;
                  });
                },
                icon: Icon(
                  _showAdvancedPicker ? Icons.palette : Icons.color_lens,
                ),
                label: Text(_showAdvancedPicker ? '预设颜色' : '高级选择'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                _showAdvancedPicker
                    ? _buildAdvancedColorPicker()
                    : _buildPresetColorPicker(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  if (selectedColor == null) {
                    ToastUtils.showWarning('请选择${widget.itemName}颜色');
                    return;
                  }

                  widget.onSubmit(nameController.text, selectedColor!);
                },
                child: const Text('创建'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetColorPicker() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...Colors.primaries.map((color) {
            final colorValue = color.toARGB32();
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = colorValue;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border:
                      selectedColor == colorValue
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdvancedColorPicker() {
    return SingleChildScrollView(
      child: ColorPicker(
        pickerColor: _pickerColor,
        onColorChanged: (Color color) {
          setState(() {
            _pickerColor = color;
            selectedColor = color.toARGB32();
          });
        },
        pickerAreaHeightPercent: 0.7,
        displayThumbColor: true,
        paletteType: PaletteType.hsvWithHue,
        portraitOnly: true,
        enableAlpha: true,
        labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
        pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
        hexInputBar: true,
      ),
    );
  }
}
