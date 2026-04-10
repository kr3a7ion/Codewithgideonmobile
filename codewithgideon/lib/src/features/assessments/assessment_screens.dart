import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/demo_data.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';

class QuizIntroScreen extends StatelessWidget {
  const QuizIntroScreen({super.key, required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.deepBlue,
                      size: 40,
                    ),
                  ),
                  const Gap(18),
                  Text(
                    'React Hooks Assessment',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Test your understanding of React Hooks concepts.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                child: Column(
                  children: [
                    AppCard(
                      radius: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quiz Details',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Gap(16),
                          const _QuizMeta(
                            icon: Icons.help_outline_rounded,
                            label: 'Questions',
                            value: '10',
                          ),
                          const Gap(14),
                          const _QuizMeta(
                            icon: Icons.schedule_rounded,
                            label: 'Duration',
                            value: '15 minutes',
                          ),
                          const Gap(14),
                          const _QuizMeta(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Passing Score',
                            value: '70%',
                          ),
                          const Gap(14),
                          const _QuizMeta(
                            icon: Icons.all_inclusive_rounded,
                            label: 'Attempts',
                            value: 'Unlimited',
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    AppCard(
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.deepBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Gap(12),
                          for (final item in const [
                            'Read each question carefully before answering.',
                            'You can navigate between questions.',
                            'Submit before the timer runs out.',
                            'Review your answers before final submission.',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '•',
                                    style: TextStyle(color: AppColors.deepBlue),
                                  ),
                                  const Gap(8),
                                  Expanded(child: Text(item)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Gap(20),
                    AppButton(
                      label: 'Start Quiz',
                      onPressed: () => context.go('/quiz/$quizId/question/1'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizQuestionScreen extends ConsumerWidget {
  const QuizQuestionScreen({
    super.key,
    required this.quizId,
    required this.questionId,
  });

  final String quizId;
  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionNumber = int.tryParse(questionId) ?? 1;
    final question = DemoData.quizQuestion(questionNumber);
    final quiz = ref.watch(quizProvider(quizId));
    final controller = ref.read(quizProvider(quizId).notifier);
    final selected = quiz.answers[questionNumber];
    final remaining = quiz.remaining;
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return AppScreen(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppGradients.primary),
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.white),
                      const Gap(8),
                      Text(
                        '$minutes:$seconds',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$questionNumber of ${DemoData.quizQuestions.length}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: questionNumber / DemoData.quizQuestions.length,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUESTION $questionNumber',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      question.text,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Gap(24),
                    for (
                      var index = 0;
                      index < question.options.length;
                      index++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () =>
                              controller.selectAnswer(questionNumber, index),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: selected == index
                                  ? AppColors.teal.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected == index
                                    ? AppColors.teal
                                    : Colors.grey.shade200,
                                width: selected == index ? 2 : 1,
                              ),
                              boxShadow: selected == index
                                  ? null
                                  : AppShadows.card,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected == index
                                        ? AppColors.teal
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected == index
                                          ? AppColors.teal
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: selected == index
                                      ? const Center(
                                          child: Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                const Gap(12),
                                Expanded(child: Text(question.options[index])),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Previous',
                      variant: AppButtonVariant.outline,
                      leading: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.deepBlue,
                      ),
                      onPressed: questionNumber == 1
                          ? null
                          : () => context.go(
                              '/quiz/$quizId/question/${questionNumber - 1}',
                            ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: AppButton(
                      label: questionNumber == DemoData.quizQuestions.length
                          ? 'Submit'
                          : 'Next',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                      onPressed: selected == null
                          ? null
                          : () => context.go(
                              questionNumber == DemoData.quizQuestions.length
                                  ? '/quiz/$quizId/results'
                                  : '/quiz/$quizId/question/${questionNumber + 1}',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizResultsScreen extends ConsumerWidget {
  const QuizResultsScreen({super.key, required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizProvider(quizId));
    final total = DemoData.quizQuestions.length;
    final correct = state.answers.isEmpty
        ? 8
        : DemoData.quizQuestions
              .where(
                (question) =>
                    state.answers[question.number] == question.correctIndex,
              )
              .length;
    final incorrect = total - correct;
    final score = ((correct / total) * 100).round();
    final passed = score >= 70;

    return AppScreen(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(42),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                child: Column(
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFACC15), Color(0xFFF59E0B)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const Gap(18),
                    Text(
                      passed ? 'Congratulations!' : 'Keep Trying!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Gap(8),
                    Text(
                      passed
                          ? "You've passed the quiz!"
                          : 'You can retake the quiz.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      AppCard(
                        radius: 32,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Container(
                              width: 144,
                              height: 144,
                              decoration: BoxDecoration(
                                gradient: passed
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF16A34A),
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          AppColors.orange,
                                          AppColors.orangeLight,
                                        ],
                                      ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$score%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                            const Gap(16),
                            Text(
                              'Your Score',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.mutedForeground),
                            ),
                            const Gap(6),
                            if (passed)
                              Text(
                                'Passed (Required: 70%)',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            const Gap(24),
                            Row(
                              children: [
                                Expanded(
                                  child: _ResultStat(
                                    icon: Icons.check_circle_rounded,
                                    label: 'Correct',
                                    value: '$correct',
                                    color: Colors.green,
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: _ResultStat(
                                    icon: Icons.cancel_rounded,
                                    label: 'Incorrect',
                                    value: '$incorrect',
                                    color: Colors.red,
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: _ResultStat(
                                    icon: Icons.schedule_rounded,
                                    label: 'Time',
                                    value: '12:45',
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (passed) ...[
                        const Gap(16),
                        AppCard(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFACC15),
                                      AppColors.orange,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(18),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const Gap(14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Achievement Unlocked!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      'React Hooks Master Badge',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Gap(20),
                      AppButton(
                        label: 'Back to Dashboard',
                        onPressed: () => context.go('/dashboard'),
                      ),
                      const Gap(10),
                      AppButton(
                        label: passed ? 'Retake Quiz' : 'Try Again',
                        variant: AppButtonVariant.outline,
                        onPressed: () {
                          ref.read(quizProvider(quizId).notifier).reset();
                          context.go('/quiz/$quizId/intro');
                        },
                      ),
                      const Gap(28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssignmentSubmissionScreen extends StatefulWidget {
  const AssignmentSubmissionScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  State<AssignmentSubmissionScreen> createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends State<AssignmentSubmissionScreen> {
  String? _selectedFile;
  final _notesController = TextEditingController();
  bool _showSuccess = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    setState(() => _selectedFile = result.files.single.name);
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Text(
                        'Submit Assignment',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Gap(14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build a Todo App with React Hooks',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Gap(10),
                        Text(
                          'Create a fully functional todo application using React Hooks. The app should support adding, completing, and deleting tasks.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.mutedForeground,
                                height: 1.7,
                              ),
                        ),
                        const Gap(14),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 18,
                                  color: AppColors.orange,
                                ),
                                const Gap(6),
                                Text(
                                  '100 points',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                            const Gap(18),
                            Text(
                              'Due: Feb 15, 2026',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(14),
                  AppCard(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requirements',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.deepBlue,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Gap(12),
                        for (final item in const [
                          'Use useState for state management',
                          'Implement useEffect for side effects',
                          'Create custom hooks for reusable logic',
                          'Include proper error handling',
                          'Write clean, commented code',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '•',
                                  style: TextStyle(color: AppColors.deepBlue),
                                ),
                                const Gap(8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Your Work',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Gap(14),
                        if (_selectedFile == null)
                          InkWell(
                            onTap: _pickFile,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 34,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                  width: 2,
                                ),
                                color: AppColors.muted,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.upload_file_rounded,
                                    size: 42,
                                    color: Colors.grey.shade500,
                                  ),
                                  const Gap(12),
                                  Text(
                                    'Upload your files',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const Gap(6),
                                  Text(
                                    'ZIP, GitHub link, or code files',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: AppColors.tealDark,
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        'Ready to submit',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _selectedFile = null),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(14),
                  AppTextField(
                    label: 'Additional Notes',
                    hint: 'Add any notes or comments for your instructor...',
                    controller: _notesController,
                    maxLines: 5,
                  ),
                  const Gap(20),
                  AppButton(
                    label: 'Submit Assignment',
                    onPressed: _selectedFile == null
                        ? null
                        : () => setState(() => _showSuccess = true),
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccess)
            Material(
              color: Colors.black.withValues(alpha: 0.72),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF16A34A)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const Gap(18),
                      Text(
                        'Submitted!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Gap(10),
                      Text(
                        'Your assignment has been submitted successfully. Your instructor will review it soon.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedForeground,
                          height: 1.6,
                        ),
                      ),
                      const Gap(20),
                      AppButton(
                        label: 'Back to Dashboard',
                        onPressed: () => context.go('/dashboard'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizMeta extends StatelessWidget {
  const _QuizMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.tealDark),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const Gap(2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color),
        ),
        const Gap(10),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Gap(4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
