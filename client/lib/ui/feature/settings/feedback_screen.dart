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
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  var _includeUserId = true;
  var _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
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
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('送信'),
          ),
        ],
      ),
      body: currentUserProfileAsync.when(
        data: (userProfile) => SingleChildScrollView(
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
                children: [
                  _buildFeedbackField(),
                  const SizedBox(height: 24),
                  _buildEmailField(),
                  const SizedBox(height: 24),
                  _buildUserIdSection(userProfile?.id),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildFeedbackField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ご意見、ご要望など',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _feedbackController,
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

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '返信用メールアドレス（任意）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'example@email.com',
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

  Widget _buildUserIdSection(String? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ユーザーID',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  userId ?? 'ユーザーIDを取得できませんでした',
                  style: TextStyle(
                    color: userId != null ? Colors.black : Colors.grey,
                  ),
                ),
                trailing: Switch(
                  value: _includeUserId,
                  onChanged: (value) {
                    setState(() {
                      _includeUserId = value;
                    });
                  },
                ),
              ),
              if (_includeUserId) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ユーザーIDを共有することで、'
                          'バグ調査がスムーズに進みます',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('送信'),
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
