import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import 'session_controller.dart';

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DropdownButton<String>(
    value: ref.watch(languageProvider),
    underline: const SizedBox.shrink(),
    items: const [
      DropdownMenuItem(value: 'en', child: Text('English')),
      DropdownMenuItem(value: 'fa', child: Text('دری / فارسی')),
      DropdownMenuItem(value: 'ps', child: Text('پښتو')),
    ],
    onChanged: (v) {
      if (v != null) ref.read(languageProvider.notifier).select(v);
    },
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final form = GlobalKey<FormState>();
  final user = TextEditingController(), password = TextEditingController();
  bool visible = false, http = false;
  @override
  void dispose() {
    user.dispose();
    password.clear();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    final secret = password.text;
    password.clear();
    await ref.read(sessionProvider.notifier).login(user.text, secret, http);
  }

  @override
  Widget build(BuildContext context) {
    final w = context.words(ref), state = ref.watch(sessionProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LanguagePicker(),
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CircleAvatar(
                        radius: 34,
                        child: Icon(Icons.wifi_rounded, size: 36),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      w('app'),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      w('welcome'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: user,
                      autofillHints: const [AutofillHints.username],
                      enabled: !state.busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: 32,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: w('username'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? w('required') : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: password,
                      autofillHints: const [AutofillHints.password],
                      enabled: !state.busy,
                      obscureText: !visible,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: 32,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: w('password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: w('password'),
                          onPressed: () => setState(() => visible = !visible),
                          icon: Icon(
                            visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? w('required') : null,
                      onFieldSubmitted: (_) {
                        if (!state.busy) submit();
                      },
                    ),
                    if (!kReleaseMode &&
                        const bool.fromEnvironment('ALLOW_HTTP'))
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: http,
                        onChanged: state.busy
                            ? null
                            : (v) {
                                setState(() => http = v ?? false);
                                if (http) {
                                  ref
                                      .read(sessionProvider.notifier)
                                      .autoLogin(http);
                                }
                              },
                        title: Text(
                          w('http'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(sessionProvider.notifier)
                                .autoLogin(http),
                      icon: const Icon(Icons.wifi_find),
                      label: Text(w('autoLogin')),
                    ),
                    Text(
                      w('autoHelp'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          w(
                            state.error!.name == 'server'
                                ? 'serverError'
                                : state.error!.name,
                          ),
                          semanticsLabel: w(state.error!.name),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: state.busy ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: state.busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(w('login')),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(w('readonly'), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
