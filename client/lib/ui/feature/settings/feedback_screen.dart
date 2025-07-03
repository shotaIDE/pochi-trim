import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/google_form_service.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  static const name = 'FeedbackScreen';

  static MaterialPageRoute<FeedbackScreen> route() =>
      MaterialPageRoute<FeedbackScreen>(
        builder: (_) => const FeedbackScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  var _includeUserId = true;
  var _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    _userIdController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProfileAsync = ref.watch(currentUserProfileProvider);
    final isSubmitting = _isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードバック'),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : _submitFeedback,
            child: Text(isSubmitting ? '送信中' : '送信'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16 + MediaQuery.of(context).viewPadding.left,
            right: 16 + MediaQuery.of(context).viewPadding.right,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                _FeedbackField(controller: _feedbackController),
                _EmailField(controller: _emailController),
                _UserIdSection(
                  controller: _userIdController,
                  includeUserId: _includeUserId,
                  onSwitchChanged: (value) {
                    setState(() {
                      _includeUserId = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _sendFeedbackToGoogleForm();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フィードバックを送信しました。ありがとうございました！'),
        ),
      );

      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('送信に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendFeedbackToGoogleForm() async {
    final currentUserProfileAsync = ref.read(currentUserProfileProvider);
    final userProfile = currentUserProfileAsync.valueOrNull;

    final feedback = _feedbackController.text.trim();
    final email = _emailController.text.trim();
    final userId = _includeUserId ? userProfile?.id : null;

    final googleFormService = ref.read(googleFormServiceProvider);
    await googleFormService.sendFeedback(
      feedback: feedback,
      email: email.isNotEmpty ? email : null,
      userId: userId,
    );
  }
}

class _FeedbackField extends StatelessWidget {
  const _FeedbackField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          'ご意見、ご要望など',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'お気づきの点やご要望をお聞かせください',
            border: OutlineInputBorder(),
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'ご意見、ご要望をご入力ください';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          '返信用メールアドレス（任意）',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'your.name@example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!emailRegex.hasMatch(value)) {
                return 'メールアドレスの形式が正しくありません';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _UserIdSection extends ConsumerWidget {
  const _UserIdSection({
    required this.controller,
    required this.includeUserId,
    required this.onSwitchChanged,
  });

  final TextEditingController controller;
  final bool includeUserId;
  final ValueChanged<bool> onSwitchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileFuture = ref.watch(currentUserProfileProvider.future);

    return FutureBuilder(
      future: userProfileFuture,
      builder: (context, snapshot) {
        final String? sendUserId;
        final String displayUserId;
        if (snapshot.hasError) {
          sendUserId = '(failed to get user ID)';
          displayUserId = '-';
        } else {
          sendUserId = snapshot.data?.id;
          displayUserId = sendUserId ?? 'xxxxxxxxxxxxxxxxxxxxxxxxxxxx';
        }

        controller.text = displayUserId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ユーザーID',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: includeUserId,
                  onChanged: (value) {
                    if (value) {
                      controller.text = displayUserId;
                    } else {
                      controller.clear();
                    }

                    onSwitchChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              enabled: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '不具合などのご報告は、ユーザーIDを共有していただくことで対応がスムーズに進むことがあります。',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
