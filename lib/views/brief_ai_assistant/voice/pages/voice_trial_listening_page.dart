import 'package:flutter/material.dart';
import '../../../../services/voice_generation_service.dart';
import '../audio_player_widget.dart';

class VoiceTrialListeningPage extends StatefulWidget {
  const VoiceTrialListeningPage({super.key});

  @override
  State<VoiceTrialListeningPage> createState() =>
      _VoiceTrialListeningPageState();
}

class _VoiceTrialListeningPageState extends State<VoiceTrialListeningPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 音频样本类型
  final List<String> _audioTypes = [
    "Qwen-TTS",
    'CosyVoice V1',
    'CosyVoice V2',
    "Sambert",
  ];

  // 当前选中的样本音频(id不一样)
  String? _currentPlayingAudio;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _audioTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('阿里云语音合成音色试听'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _audioTypes.map((type) => Tab(text: type)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 在线样本
          _buildSampleListView(VoiceGenerationService.getQwenTTSVoices()),
          _buildSampleListView(VoiceGenerationService.getV1AvailableVoices()),
          _buildSampleListView(VoiceGenerationService.getV2AvailableVoices()),
          _buildSampleListView(VoiceGenerationService.getSambertVoices()),
        ],
      ),
    );
  }

  // 构建样本列表
  Widget _buildSampleListView(List<AliyunVoiceType> samples) {
    return ListView.builder(
      padding: EdgeInsets.all(4),
      itemCount: samples.length,
      itemBuilder: (context, index) {
        final sample = samples[index];
        final isPlaying = _currentPlayingAudio == sample.id;

        return Card(
          elevation: 1,
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(
                  sample.sampleName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(sample.scene),
                trailing: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: isPlaying ? Colors.red : Colors.green,
                    size: 36,
                  ),
                  onPressed: () => _playSample(sample),
                ),
              ),

              if (isPlaying)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: AudioPlayerWidget(
                    audioUrl: sample.sampleUrl,
                    sourceType: sample.sampleType,
                    autoPlay: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 播放样本
  void _playSample(AliyunVoiceType sample) {
    setState(() {
      if (_currentPlayingAudio == sample.id) {
        _currentPlayingAudio = null;
      } else {
        _currentPlayingAudio = sample.id;
      }
    });
  }
}
