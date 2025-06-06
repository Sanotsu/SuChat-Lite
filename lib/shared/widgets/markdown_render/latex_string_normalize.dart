/// 检测输入文本是否是 Markdown 表格
bool isMarkdownTable(String text) {
  final lines = text.split('\n');
  bool hasHeaderSeparator = false;
  bool hasValidHeader = false;
  int tableStartIndex = -1;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    // 检查表头分隔线（如 `|----|----|` 或 `:---|:--:`）
    if (line.startsWith('|') &&
        line.endsWith('|') &&
        RegExp(r'^\|([:-]+\|)+$').hasMatch(line)) {
      hasHeaderSeparator = true;
      // 检查前一行是否是表头（确保是完整的表格结构）
      if (i > 0 &&
          lines[i - 1].trim().startsWith('|') &&
          lines[i - 1].contains('|', 1)) {
        hasValidHeader = true;
        tableStartIndex = i - 1;
      }
    }
  }

  // 进一步检查表格内容是否有效（至少有一行数据）
  if (hasHeaderSeparator && hasValidHeader) {
    for (int i = tableStartIndex + 2; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) break; // 表格结束（假设表格后无空行）
      if (line.startsWith('|') && line.endsWith('|')) {
        return true;
      }
    }
  }

  return false;
}

// 检测带 LaTeX 的 Markdown 表格
bool isLatexInMarkdownTable(String text) {
  if (!isMarkdownTable(text)) return false;

  // 匹配 LaTeX 公式（支持 $...$、$$...$$、\(...\)、\[...\]，排除转义字符如 \$）
  final latexPattern = RegExp(
    r'(?<!\\)\$(?!\$)(.*?)(?<!\\)\$|' // $...$
    r'(?<!\\)\$\$(?!\$)(.*?)(?<!\\)\$\$|' // $$...$$
    r'\\\(.*?\\\)|' // \(...\)
    r'\\\[(.*?)\\\]', // \[...\]
    multiLine: true,
  );

  final lines = text.split('\n');
  bool inTable = false;

  for (final line in lines) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      inTable = false; // 空行可能结束表格
      continue;
    }

    // 检查是否在表格内
    if (trimmedLine.startsWith('|') && trimmedLine.endsWith('|')) {
      inTable = true;
      if (latexPattern.hasMatch(trimmedLine)) {
        return true;
      }
    } else if (inTable) {
      // 处理表格内的多行 LaTeX（如 $$...$$ 跨行）
      if (latexPattern.hasMatch(trimmedLine)) {
        return true;
      }
    }
  }

  return false;
}

/// 将表格中的 LaTeX 语法统一替换为 \(...\) 格式
String normalizeLatexInMarkdownTable(String text) {
  if (!isMarkdownTable(text)) return text; // 非表格不处理

  final lines = text.split('\n');
  final processedLines = <String>[];

  // 正则匹配：$...$、$$...$$、\[...\]，并提取内容
  final latexPattern = RegExp(
    r'(?<!\\)\$(?!\$)(.*?)(?<!\\)\$|' // $...$
    r'(?<!\\)\$\$(?!\$)(.*?)(?<!\\)\$\$|' // $$...$$
    r'\\\[(.*?)\\\]', // \[...\]
    multiLine: true,
  );

  for (final line in lines) {
    if (line.trim().isEmpty) {
      processedLines.add(line);
      continue;
    }

    // 仅处理表格行（以 | 开头和结尾）
    if (line.trim().startsWith('|') && line.trim().endsWith('|')) {
      String processedLine = line.replaceAllMapped(latexPattern, (match) {
        // 提取公式内容（忽略 $、$$、\[ 等符号）
        String? formulaContent =
            match.group(1) ?? match.group(2) ?? match.group(3);
        return '\\($formulaContent\\)'; // 统一替换为 \(...\)
      });
      processedLines.add(processedLine);
    } else {
      processedLines.add(line); // 非表格行原样保留
    }
  }

  return processedLines.join('\n');
}

/// 把所有使用到LaTeX语法的地方，统一替换使用单行\(...\)来包裹
String normalizeAllLatex(String text) {
  // 匹配各种LaTeX格式：$...$、$$...$$、\(...\)、\[...\]
  final latexPattern = RegExp(
    r'(?<!\\)\$(?!\$)(.*?)(?<!\\)\$|' // $...$
    r'(?<!\\)\$\$(?!\$)(.*?)(?<!\\)\$\$|' // $$...$$
    r'\\\[(.*?)\\\]', // \[...\]
    multiLine: true,
  );

  // 替换为统一格式
  return text.replaceAllMapped(latexPattern, (match) {
    // 提取公式内容
    String? formulaContent = match.group(1) ?? match.group(2) ?? match.group(3);
    if (formulaContent == null) return match.group(0) ?? '';

    // 统一替换为 \(...\) 格式
    return '\\($formulaContent\\)';
  });
}

/// 将所有除了在表格内的LaTeX之外的其他使用LaTeX语法的地方，统一替换使用单行\(...\)来包裹
String normalizeNonTableLatex(String text) {
  final lines = text.split('\n');
  final processedLines = <String>[];

  // 匹配各种LaTeX格式
  final latexPattern = RegExp(
    r'(?<!\\)\$(?!\$)(.*?)(?<!\\)\$|' // $...$
    r'(?<!\\)\$\$(?!\$)(.*?)(?<!\\)\$\$|' // $$...$$
    r'\\\[(.*?)\\\]', // \[...\]
    multiLine: true,
  );

  bool inTable = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    // 判断是否在表格内
    if (line.isEmpty) {
      // 空行可能结束表格
      inTable = false;
      processedLines.add(lines[i]);
      continue;
    }

    // 检测表格开始
    if (line.startsWith('|') && line.endsWith('|')) {
      // 可能是表格行
      if (!inTable) {
        // 检查下一行是否表格分隔符
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.startsWith('|') &&
              nextLine.endsWith('|') &&
              RegExp(r'^\|([:-]+\|)+$').hasMatch(nextLine)) {
            inTable = true;
          }
        }
      }

      processedLines.add(lines[i]);
      continue;
    }

    // 非表格行进行替换
    if (!inTable) {
      final processedLine = lines[i].replaceAllMapped(latexPattern, (match) {
        String? formulaContent =
            match.group(1) ?? match.group(2) ?? match.group(3);
        if (formulaContent == null) return match.group(0) ?? '';
        return '\\($formulaContent\\)';
      });
      processedLines.add(processedLine);
    } else {
      processedLines.add(lines[i]);
    }
  }

  return processedLines.join('\n');
}

/// 将所有除了在表格内的LaTeX之外的其他使用$...$单行包裹LaTeX语法的地方，统一替换使用单行\(...\)来包裹
String normalizeInlineMathLatex(String text) {
  final lines = text.split('\n');
  final processedLines = <String>[];

  // 仅匹配行内单美元符号包裹的LaTeX：$...$
  final inlineLatexPattern = RegExp(
    r'(?<!\\)\$(?!\$)(.*?)(?<!\\)\$', // $...$
    multiLine: true,
  );

  bool inTable = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    // 判断是否在表格内
    if (line.isEmpty) {
      // 空行可能结束表格
      inTable = false;
      processedLines.add(lines[i]);
      continue;
    }

    // 检测表格开始
    if (line.startsWith('|') && line.endsWith('|')) {
      // 可能是表格行
      if (!inTable) {
        // 检查下一行是否表格分隔符
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.startsWith('|') &&
              nextLine.endsWith('|') &&
              RegExp(r'^\|([:-]+\|)+$').hasMatch(nextLine)) {
            inTable = true;
          }
        }
      }

      processedLines.add(lines[i]);
      continue;
    }

    // 非表格行进行替换
    if (!inTable) {
      final processedLine = lines[i].replaceAllMapped(inlineLatexPattern, (
        match,
      ) {
        String? formulaContent = match.group(1);
        if (formulaContent == null) return match.group(0) ?? '';
        return '\\($formulaContent\\)';
      });
      processedLines.add(processedLine);
    } else {
      processedLines.add(lines[i]);
    }
  }

  return processedLines.join('\n');
}

/// 将所有使用$...$包裹的单行LaTeX语法替换为\(...\)包裹
String convertDollarToParenthesesLatex(String text) {
  // 匹配单个美元符号包裹的LaTeX公式：$...$
  // 注意: 确保不匹配 $$...$$ 和 \$
  final inlineLatexPattern = RegExp(
    r'(?<!\$)(?<!\\)\$(?!\$)(.*?)(?<!\\)\$(?!\$)', // 确保前后不是$，也不是\$
    multiLine: true,
  );

  // 替换为统一格式
  return text.replaceAllMapped(inlineLatexPattern, (match) {
    String? formulaContent = match.group(1);
    if (formulaContent == null) return match.group(0) ?? '';
    return '\\($formulaContent\\)';
  });
}
