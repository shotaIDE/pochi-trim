import 'package:flutter/material.dart';

/// 分析画面
///
/// 家事の実行頻度や曜日ごとの頻度分析を表示する
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  /// 分析方式
  /// 0: 家事の頻度分析
  /// 1: 曜日ごとの頻度分析
  var _analysisMode = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        // ホーム画面への動線
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // 分析方式の切り替えUI
          _buildAnalysisModeSwitcher(),

          // 分析結果表示
          Expanded(
            child:
                _analysisMode == 0
                    ? _buildFrequencyAnalysis()
                    : _buildWeekdayAnalysis(),
          ),
        ],
      ),
    );
  }

  /// 分析方式の切り替えUIを構築
  Widget _buildAnalysisModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment<int>(value: 0, label: Text('家事の頻度分析')),
          ButtonSegment<int>(value: 1, label: Text('曜日ごとの頻度分析')),
        ],
        selected: {_analysisMode},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() {
            _analysisMode = newSelection.first;
          });
        },
      ),
    );
  }

  /// 家事の頻度分析を表示するウィジェットを構築
  Widget _buildFrequencyAnalysis() {
    // サンプルデータ（実際の実装では、リポジトリからデータを取得する）
    final sampleData = <Map<String, dynamic>>[
      {'name': '食器洗い', 'count': 32, 'icon': '🍽️'},
      {'name': '掃除機がけ', 'count': 24, 'icon': '🧹'},
      {'name': '洗濯', 'count': 21, 'icon': '👕'},
      {'name': 'ゴミ出し', 'count': 18, 'icon': '🗑️'},
      {'name': '料理', 'count': 15, 'icon': '🍳'},
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '家事の実行頻度（回数が多い順）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: sampleData.length,
                itemBuilder: (context, index) {
                  final item = sampleData[index];
                  return ListTile(
                    leading: Text(
                      item['icon'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(item['name'] as String),
                    trailing: Text(
                      '${item['count']}回',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 曜日ごとの頻度分析を表示するウィジェットを構築
  Widget _buildWeekdayAnalysis() {
    // サンプルデータ（実際の実装では、リポジトリからデータを取得する）
    final sampleData = <Map<String, dynamic>>[
      {'weekday': '月曜日', 'count': 12},
      {'weekday': '火曜日', 'count': 8},
      {'weekday': '水曜日', 'count': 15},
      {'weekday': '木曜日', 'count': 10},
      {'weekday': '金曜日', 'count': 9},
      {'weekday': '土曜日', 'count': 22},
      {'weekday': '日曜日', 'count': 18},
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '曜日ごとの家事実行頻度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: sampleData.length,
                itemBuilder: (context, index) {
                  final item = sampleData[index];
                  // 最大値に対する割合に基づいてバーの長さを決定
                  final maxCount = sampleData
                      .map((e) => e['count'] as int)
                      .reduce((a, b) => a > b ? a : b);
                  final ratio = (item['count'] as int) / maxCount.toDouble();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['weekday'] as String),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              flex: (ratio * 100).toInt(),
                              child: Container(
                                height: 24,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            if (ratio < 1)
                              Expanded(
                                flex: 100 - (ratio * 100).toInt(),
                                child: Container(),
                              ),
                            const SizedBox(width: 8),
                            Text('${item['count']}回'),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
