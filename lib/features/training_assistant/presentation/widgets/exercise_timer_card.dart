import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/tts_helper.dart';
import '../../domain/entities/training_plan_detail.dart';

class ExerciseTimerCard extends StatefulWidget {
  final TrainingPlanDetail exercise;
  final int currentSet;
  final bool isResting;
  // 当前组完成
  final VoidCallback onSetCompleted;
  // 跳过当前组
  final VoidCallback onSkipCurrentSet;
  // 休息时间结束
  final VoidCallback onRestCompleted;

  const ExerciseTimerCard({
    super.key,
    required this.exercise,
    required this.currentSet,
    required this.isResting,
    required this.onSetCompleted,
    required this.onSkipCurrentSet,
    required this.onRestCompleted,
  });

  @override
  State<ExerciseTimerCard> createState() => _ExerciseTimerCardState();
}

class _ExerciseTimerCardState extends State<ExerciseTimerCard> {
  late Timer _timer;
  late int _countdown;
  bool _isPaused = false;

  // TTS助手实例
  final TTSHelper _ttsHelper = TTSHelper();

  @override
  void initState() {
    super.initState();
    _initializeTimer();

    // 初始化TTS
    _ttsHelper.init().then((_) {
      // 播放相应的语音提示
      _playInitialVoicePrompt();
    });
  }

  @override
  void didUpdateWidget(ExerciseTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isResting != widget.isResting ||
        oldWidget.currentSet != widget.currentSet ||
        oldWidget.exercise.detailId != widget.exercise.detailId) {
      _timer.cancel();
      _initializeTimer();

      // 播放相应的语音提示
      _playInitialVoicePrompt();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    // 确保停止所有TTS声音
    _ttsHelper.stop();
    super.dispose();
  }

  void _initializeTimer() {
    // 如果是休息状态，使用休息时间；否则使用默认的锻炼时间
    _countdown =
        widget.isResting ? widget.exercise.restTime : widget.exercise.countdown;
    _isPaused = false;

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;

            // 播放倒计时语音提示
            _playCountdownVoicePrompts();
          } else {
            _timer.cancel();

            // 播放结束语音提示
            // ？？？注意:这里如果speaknow报错了，就没有调用onRestCompleted和onSetCompleted，可能有问题
            if (_ttsHelper.isSupported) {
              // 休息结束
              if (widget.isResting) {
                try {
                  _ttsHelper.speakNow("休息结束，准备下一组");
                } finally {
                  // 使用延迟避免语音和UI更新冲突
                  Future.delayed(Duration(milliseconds: 3000), () {
                    if (mounted) {
                      widget.onRestCompleted();
                    }
                  });
                }
              } else {
                // 组完成和全部完成的提示作为队列播放
                try {
                  if (widget.currentSet < widget.exercise.sets) {
                    _ttsHelper.speakNow(
                      "第${widget.currentSet} 组完成，共${widget.exercise.sets}组",
                    );
                  } else {
                    _ttsHelper.speakNow("所有组数已完成");
                  }
                } finally {
                  // 使用延迟避免语音和UI更新冲突
                  Future.delayed(Duration(milliseconds: 3000), () {
                    if (mounted) {
                      widget.onSetCompleted();
                    }
                  });
                }
              }
            } else {
              // 不支持TTS的平台直接调用回调
              if (widget.isResting) {
                widget.onRestCompleted();
              } else {
                widget.onSetCompleted();
              }
            }
          }
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;

      // 播放暂停/继续语音提示
      if (_ttsHelper.isSupported) {
        if (_isPaused) {
          // 清空之前的语音队列，立即播放暂停提示
          _ttsHelper.speakNow('暂停');
        } else {
          // 清空之前的语音队列，立即播放继续提示
          _ttsHelper.speakNow('继续');
        }
      }
    });
  }

  void _addRestTime(int seconds) {
    if (widget.isResting) {
      setState(() {
        _countdown += seconds;
        if (_ttsHelper.isSupported) {
          // 使用队列播放增加休息时间提示
          _ttsHelper.speak('增加了$seconds秒休息时间');
        }
      });
    }
  }

  // 播放初始语音提示
  Future<void> _playInitialVoicePrompt() async {
    // 检查平台是否支持TTS
    if (!_ttsHelper.isSupported) return;

    if (widget.isResting) {
      // 使用立即播放，确保休息提示被立即播放
      await _ttsHelper.speakNow('休息 ${widget.exercise.restTime} 秒');
    } else {
      // 如果是新的动作，播放动作名称和说明
      if (widget.currentSet == 1) {
        // 使用立即播放，确保动作开始提示被立即播放
        await _ttsHelper.speakNow('开始 ${widget.exercise.exerciseName}');

        // 如果有动作说明，播放说明(有点瑕疵，用户连续跳过动作后，这个可能会异常播放)
        if (widget.exercise.instructions != null &&
            widget.exercise.instructions!.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 3));
          _ttsHelper.speakNow(widget.exercise.instructions!);
        }
      } else {
        // 如果是继续同一动作的下一组，播放组数信息
        await _ttsHelper.speakNow(
          '开始第${widget.currentSet}组，共${widget.exercise.sets}组',
        );
      }
    }
  }

  // 播放倒计时语音提示
  void _playCountdownVoicePrompts() {
    // 如果平台不支持TTS或计时器暂停，直接返回
    if (!_ttsHelper.isSupported || _isPaused) return;

    // 计算倒计时的一半时间
    final halfTime =
        (widget.isResting
            ? widget.exercise.restTime
            : widget.exercise.countdown) ~/
        2;

    // 不使用最后321的倒计时，避免语音冲突
    if (widget.isResting) {
      // 休息时间的提示
      if (_countdown == 5) {
        _ttsHelper.speak('休息时间即将结束');
      }
    } else {
      // 锻炼时间的提示
      // 播放半程提示
      if (_countdown == halfTime) {
        _ttsHelper.speak("已完成一半");
      }

      // 播放即将结束提示（最后5秒）
      if (_countdown == 5) {
        _ttsHelper.speak("即将完成");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          // 外层使用Center使内容居中
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 动作名称和状态（带说明图标）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.exercise.exerciseName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.exercise.instructions != null &&
                      widget.exercise.instructions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Tooltip(
                        message: widget.exercise.instructions!,
                        child: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('动作说明'),
                                    content: Text(
                                      widget.exercise.instructions!,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('关闭'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.isResting
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.isResting ? '休息中' : '锻炼中',
                      style: TextStyle(
                        color: widget.isResting ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// 肌肉群组
              Text(
                '目标肌群: ${widget.exercise.muscleGroup}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              /// 组数和重复次数
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildInfoChip(
                    icon: Icons.repeat,
                    label: '组数',
                    value: '${widget.currentSet}/${widget.exercise.sets}',
                  ),
                  _buildInfoChip(
                    icon: Icons.fitness_center,
                    label: '重复次数',
                    value: widget.exercise.reps,
                  ),
                  _buildInfoChip(
                    icon: Icons.timer,
                    label: '休息时间',
                    value: '${widget.exercise.restTime}秒',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 倒计时显示
              Column(
                children: [
                  Text(
                    widget.isResting ? '休息倒计时' : '锻炼倒计时',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatSecondsToMMSS(_countdown),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color:
                          _countdown < 5
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 控制按钮
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? '继续' : '暂停'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaused ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // 非休息状态下的跳过本组按钮
                  if (!widget.isResting)
                    TextButton.icon(
                      icon: const Icon(Icons.fast_forward),
                      label: const Text('跳过本组'),
                      onPressed: widget.onSkipCurrentSet,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),

                  if (widget.isResting)
                    OutlinedButton.icon(
                      onPressed: () => _addRestTime(15),
                      icon: const Icon(Icons.add),
                      label: const Text('加15秒'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
