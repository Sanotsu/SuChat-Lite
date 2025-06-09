// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../core/utils/tts_helper.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';
import '../../domain/entities/training_record_detail.dart';
import '../viewmodels/training_viewmodel.dart';
import '../widgets/exercise_timer_card.dart';

class WorkoutSessionPage extends StatefulWidget {
  final TrainingPlan plan;
  final List<TrainingPlanDetail> details;
  final int day;

  const WorkoutSessionPage({
    super.key,
    required this.plan,
    required this.details,
    required this.day,
  });

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  // 常量定义
  static const int DEFAULT_EXERCISE_REST_TIME = 60; // 默认动作间休息时间（秒）

  // 当前训练的状态
  late List<TrainingPlanDetail> _todaysExercises;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  bool _isCompleted = false;
  bool _isSaving = false;

  // 动作之间的休息
  bool _isRestingBetweenExercises = false;
  int _exerciseRestCountdown = DEFAULT_EXERCISE_REST_TIME; // 使用常量初始化
  Timer? _exerciseRestTimer;

  // 准备时间状态
  bool _isPreparing = true;
  int _preparationCountdown = 15; // 15秒准备时间
  Timer? _preparationTimer;

  // 训练记录
  late Stopwatch _totalTimeStopwatch;
  List<TrainingRecordDetail> _recordDetails = [];
  // 跟踪每个动作实际完成的组数
  late List<int> _completedSetsPerExercise;

  // TTS助手
  final TTSHelper _ttsHelper = TTSHelper();

  @override
  void initState() {
    super.initState();
    // 初始化日期格式本地化
    initializeDateFormatting('zh_CN');

    _initWorkout();

    // 初始化TTS
    _ttsHelper.init().then((_) {
      // 启动准备倒计时
      _startPreparationTimer();
    });
  }

  void _startPreparationTimer() {
    if (_ttsHelper.isSupported) {
      // 使用立即播放，确保这是第一个播放的语音
      _ttsHelper.speakNow('运动即将开始，请做好准备');
    }

    _preparationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_preparationCountdown > 0) {
          _preparationCountdown--;

          // 倒计时最后3秒
          // if (_ttsHelper.isSupported && _preparationCountdown == 3) {
          //   // 使用队列播放倒计时数字
          //   _ttsHelper.speak('即将开始');
          // }
        } else {
          // 倒计时结束，取消计时器
          // 准备倒计时结束后，会进入动作跟练页面，里面会有相关语音，不需要在这里tts
          timer.cancel();
          _isPreparing = false;
        }
      });
    });
  }

  @override
  void dispose() {
    // 确保停止所有TTS声音
    _ttsHelper.stop();

    if (_preparationTimer != null && _preparationTimer!.isActive) {
      _preparationTimer!.cancel();
    }
    if (_exerciseRestTimer != null && _exerciseRestTimer!.isActive) {
      _exerciseRestTimer!.cancel();
    }
    _ttsHelper.dispose();
    _totalTimeStopwatch.stop();
    super.dispose();
  }

  void _initWorkout() {
    // 过滤当天的训练内容
    _todaysExercises =
        widget.details.where((detail) => detail.day == widget.day).toList();

    // 初始化每个动作实际完成的组数为0
    _completedSetsPerExercise = List.filled(_todaysExercises.length, 0);

    // 初始化训练记录
    _recordDetails =
        _todaysExercises.map((exercise) {
          return TrainingRecordDetail(
            recordId: '', // 将在保存时设置
            detailId: exercise.detailId,
            exerciseName: exercise.exerciseName,
            completed: false,
            actualSets: 0,
            actualReps: '0',
            notes: null,
          );
        }).toList();

    _totalTimeStopwatch = Stopwatch()..start();
  }

  // 下一个动作
  void _nextExercise() {
    if (_currentExerciseIndex < _todaysExercises.length - 1) {
      setState(() {
        // 更新当前动作的完成状态
        final currentExercise = _todaysExercises[_currentExerciseIndex];

        _recordDetails[_currentExerciseIndex] =
            _recordDetails[_currentExerciseIndex].copyWith(
              completed: true,
              actualSets: _completedSetsPerExercise[_currentExerciseIndex],
              actualReps: currentExercise.reps,
            );

        // 开始动作之间的休息
        _startRestBetweenExercises();
      });
    } else {
      // 所有动作完成
      _completeWorkout();
    }
  }

  // 开始动作之间的休息(这个是动作间休息，ExerciseTimerCard中是组间休息)
  void _startRestBetweenExercises() {
    setState(() {
      _isRestingBetweenExercises = true;
      // 重置动作间休息倒计时为默认值
      _exerciseRestCountdown = DEFAULT_EXERCISE_REST_TIME;
    });

    // 播放动作间休息提示，使用speakNow确保立即播放
    if (_ttsHelper.isSupported) {
      _ttsHelper.speakNow('动作完成，休息$_exerciseRestCountdown秒后进行下一个动作');
    }

    _exerciseRestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_exerciseRestCountdown > 0) {
          _exerciseRestCountdown--;

          if (_ttsHelper.isSupported) {
            // 休息即将结束提示
            if (_exerciseRestCountdown == 8) {
              _ttsHelper.speakNow('休息即将结束，准备下一个动作');
            }
          }
        } else {
          timer.cancel();
          _isRestingBetweenExercises = false;

          // 进入下一个动作
          // 动作之间倒计时结束后，会进入动作跟练页面，里面会有相关语音，不需要在这里tts
          _currentExerciseIndex++;
          _currentSet = 1;
          _isResting = false;
        }
      });
    });
  }

  // 跳过当前动作
  void _skipExercise() {
    // 如果是有完成了几组之后跳过，则也当做该动作已完成
    // 一组没完成直接跳过则标记未完成，直接进入下一个动作跟练
    var completedSets = _completedSetsPerExercise[_currentExerciseIndex];

    // 更新当前动作的完成状态
    setState(() {
      _recordDetails[_currentExerciseIndex] =
          _recordDetails[_currentExerciseIndex].copyWith(
            completed: completedSets > 0 ? true : false,
            actualSets: completedSets,
            notes: '${completedSets > 0 ? '完成$completedSets组后' : ''}跳过了此动作',
          );
    });

    // 不是最后一个动作
    if (_currentExerciseIndex < _todaysExercises.length - 1) {
      setState(() {
        // 如果正在动作间休息，取消休息计时器
        if (_isRestingBetweenExercises &&
            _exerciseRestTimer != null &&
            _exerciseRestTimer!.isActive) {
          _exerciseRestTimer!.cancel();
          _isRestingBetweenExercises = false;
        }

        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
      });
    } else {
      // 最后一个动作，完成训练
      _completeWorkout();
    }
  }

  // 跳过动作间休息
  void _skipExerciseRest() {
    if (_isRestingBetweenExercises &&
        _exerciseRestTimer != null &&
        _exerciseRestTimer!.isActive) {
      _exerciseRestTimer!.cancel();

      setState(() {
        _isRestingBetweenExercises = false;

        // 进入下一个动作
        // 动作之间倒计时结束后，会进入动作跟练页面，里面会有相关语音，不需要在这里tts
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
      });
    }
  }

  // 下一组
  void _nextSet() {
    final currentExercise = _todaysExercises[_currentExerciseIndex];

    setState(() {
      // 增加当前动作已完成的组数
      _completedSetsPerExercise[_currentExerciseIndex]++;

      if (_currentSet < currentExercise.sets) {
        _currentSet++;
        _isResting = true;
      } else {
        // 当前动作的所有组都完成了
        _recordDetails[_currentExerciseIndex] =
            _recordDetails[_currentExerciseIndex].copyWith(
              completed: true,
              actualSets: _completedSetsPerExercise[_currentExerciseIndex],
              actualReps: currentExercise.reps,
            );
        _nextExercise();
      }
    });
  }

  // 休息结束或者跳过休息时重置状态
  void _spikRest() {
    // 不增加组数，只是重新开始当前组
    setState(() {
      _isResting = false;
    });
  }

  // // 显示完成情况的调试信息
  // void _debugPrintCompletionStatus() {
  //   print('=== 训练完成情况 ===');
  //   for (int i = 0; i < _todaysExercises.length; i++) {
  //     final exercise = _todaysExercises[i];
  //     final completed = _recordDetails[i].completed;
  //     final actualSets = _completedSetsPerExercise[i];
  //     final totalSets = exercise.sets;

  //     print('动作 ${i + 1}: ${exercise.exerciseName}');
  //     print('  完成状态: ${completed ? "已完成" : "未完成"}');
  //     print('  实际完成组数: $actualSets / $totalSets');
  //     print('  备注: ${_recordDetails[i].notes ?? "无"}');
  //   }
  //   print('====================');
  // }

  // 跳过当前组
  void _skipCurrentSet() {
    final currentExercise = _todaysExercises[_currentExerciseIndex];

    setState(() {
      // 如果当前是休息状态，取消休息
      if (_isResting) {
        _isResting = false;
      }

      // 记录跳过的组
      if (_recordDetails[_currentExerciseIndex].notes == null) {
        _recordDetails[_currentExerciseIndex] =
            _recordDetails[_currentExerciseIndex].copyWith(
              notes: '跳过了第$_currentSet组',
            );
      } else {
        // 如果已有备注，则追加
        _recordDetails[_currentExerciseIndex] =
            _recordDetails[_currentExerciseIndex].copyWith(
              notes:
                  '${_recordDetails[_currentExerciseIndex].notes}，跳过了第$_currentSet组',
            );
      }

      // 检查是否还有下一组
      if (_currentSet < currentExercise.sets) {
        _currentSet++; // 移至下一组
        _isResting = true; // 进入组间休息
      } else {
        // 已是最后一组，完成当前动作
        _recordDetails[_currentExerciseIndex] =
            _recordDetails[_currentExerciseIndex].copyWith(
              // 动作标记为已完成
              completed: true,
              // 实际完成的组数
              actualSets: _completedSetsPerExercise[_currentExerciseIndex],
              actualReps: _todaysExercises[_currentExerciseIndex].reps,
            );

        // 进入下一个动作
        if (_currentExerciseIndex < _todaysExercises.length - 1) {
          // 开始动作之间的休息
          _startRestBetweenExercises();
        } else {
          // 所有动作完成
          _completeWorkout();
        }
      }
    });
  }

  // 完成训练
  void _completeWorkout() {
    // 打印训练完成情况（调试用）
    // _debugPrintCompletionStatus();

    // 确保停止所有TTS声音
    _ttsHelper.stop();

    // 更新状态
    setState(() {
      _isCompleted = true;
      _totalTimeStopwatch.stop();
    });

    // 计算完成率
    int completedExercises =
        _recordDetails.where((detail) => detail.completed).length;
    double completionRate = completedExercises / _todaysExercises.length;

    // 播放训练完成的语音提示
    if (_ttsHelper.isSupported) {
      // 使用立即播放，确保立即播放训练完成提示
      _ttsHelper
          .speakNow('恭喜，锻炼已结束！')
          .then((_) {
            // 保存训练记录
            if (mounted) {
              _saveTrainingRecord(completionRate);
            }
          })
          .catchError((e) {
            pl.e('播放训练完成提示错误: $e');
            // 即使播放失败，也保存记录
            if (mounted) {
              _saveTrainingRecord(completionRate);
            }
          });
    } else {
      // 不支持TTS的平台直接保存训练记录
      _saveTrainingRecord(completionRate);
    }
  }

  // 保存训练记录
  Future<void> _saveTrainingRecord(double completionRate) async {
    // 确保停止所有TTS声音
    _ttsHelper.stop();

    setState(() {
      _isSaving = true;
    });

    try {
      final viewModel = Provider.of<TrainingViewModel>(context, listen: false);

      // 计算训练时长（分钟）
      final durationInMinutes = _totalTimeStopwatch.elapsed.inMinutes;

      // 更新所有训练记录详情的实际完成情况
      for (int i = 0; i < _recordDetails.length; i++) {
        if (i > _currentExerciseIndex) {
          // 未到达的动作标记为未完成
          _recordDetails[i] = _recordDetails[i].copyWith(
            completed: false,
            actualSets: 0,
          );
        } else if (i == _currentExerciseIndex && !_isCompleted) {
          // 当前动作更新为当前完成的组数
          final isLastSet = _currentSet == _todaysExercises[i].sets;
          _recordDetails[i] = _recordDetails[i].copyWith(
            completed: isLastSet, // 如果是最后一组，则标记为已完成
            actualSets: _completedSetsPerExercise[i], // 实际完成的组数
          );
        }

        // 计算每个动作的完成率
        if (_recordDetails[i].completed) {
          final exercise = _todaysExercises[i];
          final completionRateForExercise =
              _completedSetsPerExercise[i] / exercise.sets;

          // 如果完成率低于100%，添加备注
          if (completionRateForExercise < 1.0 &&
              (_recordDetails[i].notes == null ||
                  !_recordDetails[i].notes!.contains('完成率'))) {
            final currentNotes = _recordDetails[i].notes;
            final completionNote =
                '完成率: ${(completionRateForExercise * 100).round()}%';

            _recordDetails[i] = _recordDetails[i].copyWith(
              notes:
                  currentNotes == null
                      ? completionNote
                      : '$currentNotes，$completionNote',
            );
          }
        }
      }

      // 记录训练
      await viewModel.recordTraining(
        duration: durationInMinutes,
        completionRate: completionRate,
        caloriesBurned: null, // 可以根据实际情况计算
        feedback: null,
        recordDetails: _recordDetails,
      );

      // 显示完成提示
      // ToastUtils.showInfo("训练记录已保存！", align: Alignment.center);

      setState(() {
        _isSaving = false;
      });

      // 延迟后跳转到训练统计页面
      // Future.delayed(const Duration(seconds: 1), () {
      //   if (mounted) {
      //     // 返回到训练助手主页面并切换到训练统计标签
      //     Navigator.of(context).pop({'switchToStatistics': true});
      //   }
      // });
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, "保存训练记录失败", e.toString());

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_todaysExercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('训练模式')),
        body: const Center(child: Text('今天没有安排训练内容')),
      );
    }

    final currentExercise = _todaysExercises[_currentExerciseIndex];
    final totalExercises = _todaysExercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '训练模式 - ${DateFormat('EEEE', 'zh_CN').format(DateTime.now())}',
        ),
        actions: [
          if (!_isCompleted)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // 显示确认对话框
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('结束训练'),
                        content: const Text('确定要结束当前训练吗？您的训练记录将被保存。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _completeWorkout();
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 如果平台不支持TTS，显示提示信息
          if (!_ttsHelper.isSupported)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.volume_off, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当前平台不支持语音提示功能',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // 主体内容
          Expanded(
            child:
                _isCompleted
                    ? _buildCompletionScreen()
                    : _isPreparing
                    ? _buildPreparationScreen()
                    : _isRestingBetweenExercises
                    ? _buildExerciseRestScreen()
                    : Padding(
                      padding: const EdgeInsets.all(5),
                      child: _buildWorkoutScreen(
                        currentExercise,
                        totalExercises,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // 准备倒计时界面
  Widget _buildPreparationScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('准备开始', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          Text(
            _preparationCountdown.toString(),
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: _preparationCountdown <= 3 ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(height: 32),
          Text('请做好准备', style: Theme.of(context).textTheme.titleLarge),
          if (_todaysExercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '第一个动作: ${_todaysExercises[0].exerciseName}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // 动作之间休息界面
  Widget _buildExerciseRestScreen() {
    final nextExerciseIndex = _currentExerciseIndex + 1;
    final nextExercise = _todaysExercises[nextExerciseIndex];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('休息时间', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          Text(
            _exerciseRestCountdown.toString(),
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: _exerciseRestCountdown <= 5 ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          Text('下一个动作', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              nextExercise.exerciseName,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (nextExercise.instructions != null &&
              nextExercise.instructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 100),
                child: SingleChildScrollView(
                  child: Text(
                    nextExercise.instructions!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.skip_next),
            label: const Text('跳过休息'),
            onPressed: _skipExerciseRest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutScreen(
    TrainingPlanDetail currentExercise,
    int totalExercises,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 进度指示器
        LinearProgressIndicator(
          value:
              (_currentExerciseIndex +
                  (_currentSet - 1) / currentExercise.sets) /
              totalExercises,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        // 训练信息
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '动作 ${_currentExerciseIndex + 1}/$totalExercises',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '总时间: ${formatSecondsToMMSS(_totalTimeStopwatch.elapsed.inSeconds)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),

        // 中间可滚动的内容区域（卡片居中）
        Expanded(
          child: Center(
            // 使用Center使卡片居中
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: ExerciseTimerCard(
                    exercise: currentExercise,
                    currentSet: _currentSet,
                    isResting: _isResting,
                    onSetCompleted: _nextSet,
                    onSkipCurrentSet: _skipCurrentSet,
                    onRestCompleted: _spikRest,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 控制按钮
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    label: const Text(
                      '跳过动作',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _skipExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: Text(
                      _isResting ? '跳过休息' : '完成本组',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: _isResting ? _spikRest : _nextSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    // 计算完成率
    int completedExercises =
        _recordDetails.where((detail) => detail.completed).length;
    double completionRate = completedExercises / _todaysExercises.length;
    int completionPercentage = (completionRate * 100).round();

    return Center(
      child:
          _isSaving
              ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在保存训练记录...'),
                ],
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    '训练完成！',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '训练时长: ${formatSecondsToMMSS(_totalTimeStopwatch.elapsed.inSeconds)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '完成率: $completionPercentage%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('返回'),
                    onPressed: () {
                      // 延迟后返回到训练助手主页面并切换到训练统计标签
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).pop({'switchToStatistics': true});
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
