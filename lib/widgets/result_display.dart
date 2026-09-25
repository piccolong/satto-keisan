import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 計算結果を大きなフォントで表示し、タップでクリップボードにコピーする。
/// [resultText] が空の場合はプレースホルダーを表示する。
class ResultDisplay extends StatelessWidget {
  const ResultDisplay({
    super.key,
    required this.resultText,
    this.label,
  });

  /// 結果の値(例: "1,250円")。空文字なら未計算とみなす。
  final String resultText;

  /// 結果の上に表示する小さなラベル(例: "1人あたり")。
  final String? label;

  Future<void> _copyToClipboard(BuildContext context) async {
    if (resultText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: resultText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('結果をコピーしました'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasResult = resultText.isNotEmpty;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasResult ? () => _copyToClipboard(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                hasResult ? resultText : '-',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
              if (hasResult) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'タップしてコピー',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
