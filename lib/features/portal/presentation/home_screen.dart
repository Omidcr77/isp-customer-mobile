import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../auth/login_screen.dart';
import '../../auth/session_controller.dart';
import '../domain/portal.dart';
import '../data/html_adapter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PortalSection section = PortalSection.dashboard;
  bool settings = false;
  Map<String, String> usage = {};
  String report = 'ServiceHistory';
  PortalPage? data;
  PortalFailure? error;
  bool loading = true;
  int epoch = 0;
  DateTime? backgroundAt;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(load);
  }

  @override
  void dispose() {
    epoch++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      backgroundAt = DateTime.now();
      setState(() => data = null);
    }
    if (state == AppLifecycleState.resumed) {
      if (backgroundAt != null &&
          DateTime.now().difference(backgroundAt!) >=
              const Duration(minutes: 15)) {
        ref.read(sessionProvider.notifier).expire();
      } else {
        load();
      }
    }
  }

  Future<void> load() async {
    final current = ++epoch;
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
      data = null;
    });
    try {
      final result = await ref
          .read(repositoryProvider)
          .read(section, usage: usage, report: report);
      if (mounted && current == epoch) {
        setState(() {
          data = result;
          loading = false;
        });
      }
    } on PortalException catch (e) {
      if (!mounted || current != epoch) return;
      if (e.kind == PortalFailure.expired) {
        await ref.read(sessionProvider.notifier).expire();
        return;
      }
      setState(() {
        error = e.kind;
        loading = false;
      });
    } catch (_) {
      if (mounted && current == epoch) {
        setState(() {
          error = PortalFailure.server;
          loading = false;
        });
      }
    }
  }

  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.router_outlined,
    Icons.data_usage,
    Icons.bar_chart,
    Icons.account_balance_wallet_outlined,
    Icons.receipt_long_outlined,
    Icons.inventory_2_outlined,
    Icons.assessment_outlined,
    Icons.folder_outlined,
    Icons.notifications_none,
    Icons.person_outline,
    Icons.description_outlined,
  ];
  void select(PortalSection value) {
    setState(() {
      section = value;
      settings = false;
      usage = {};
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    final w = context.words(ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(w(settings ? 'settings' : section.name)),
        actions: [
          IconButton(
            tooltip: w('settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => setState(() => settings = true),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  w('app'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              for (final s in PortalSection.values)
                ListTile(
                  leading: Icon(icons[s.index]),
                  title: Text(w(s.name)),
                  selected: !settings && section == s,
                  onTap: () {
                    Navigator.pop(context);
                    select(s);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(w('settings')),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => settings = true);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: settings
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    w('language'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const LanguagePicker(),
                  const SizedBox(height: 24),
                  Text(w('settingsNote')),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(sessionProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    label: Text(w('logout')),
                  ),
                ],
              )
            : RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (error != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 40),
                              const SizedBox(height: 16),
                              Text(
                                w(
                                  error!.name == 'server'
                                      ? 'serverError'
                                      : error!.name,
                                ),
                              ),
                              TextButton(
                                onPressed: load,
                                child: Text(w('retry')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (data != null) ...content(w, data!),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: settings
            ? 3
            : section == PortalSection.usage
            ? 1
            : section == PortalSection.payments
            ? 2
            : 0,
        onDestinationSelected: (i) {
          if (i == 3) {
            setState(() => settings = true);
          } else {
            select(
              [
                PortalSection.dashboard,
                PortalSection.usage,
                PortalSection.payments,
              ][i],
            );
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view),
            label: w('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: w('usage'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long),
            label: w('payments'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune),
            label: w('settings'),
          ),
        ],
      ),
    );
  }

  List<Widget> content(Words w, PortalPage page) {
    final children = <Widget>[];
    if (section == PortalSection.notifications ||
        section == PortalSection.invoices) {
      return [
        notice(
          w(
            section == PortalSection.notifications
                ? 'notificationsNote'
                : 'invoicesNote',
          ),
        ),
      ];
    }
    if (section == PortalSection.profile) {
      children.add(notice(w('profileNote')));
    }
    if (page.notice != null) children.add(notice(w(page.notice!)));
    if ([PortalSection.dashboard, PortalSection.traffic].contains(section) &&
        page.totalBytes != null) {
      final used = page.usedBytes!, total = page.totalBytes!;
      children.add(
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(w('remaining')),
              Text(
                '${((total - used) / 1073741824).toStringAsFixed(2)} GiB',
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: total > 0 ? (used / total).clamp(0, 1) : 0,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              Text(
                '${w('used')}: ${(used / 1073741824).toStringAsFixed(2)} GiB',
              ),
            ],
          ),
        ),
      );
    }
    if (section == PortalSection.dashboard && page.hourlyBytes.isNotEmpty) {
      children.add(
        UsageChart(
          title: w('hourly'),
          values: page.hourlyBytes.map((e) => e / 1073741824).toList(),
          labels: List.generate(page.hourlyBytes.length, (i) => '$i'),
        ),
      );
    }
    final fields = page.fields.where((f) {
      if (section == PortalSection.service) {
        return [
          'وضعیت اشتراک',
          'مجوز اتصال',
          'سرویس فعال',
          'تاریخ شروع سرویس',
          'تاریخ پایان سرویس',
          'مدت کل سرویس (روز)',
          'مصرف شده (روز)',
          'باقیمانده (روز)',
        ].contains(f.label);
      }
      if (section == PortalSection.balance) {
        return ['وضعیت اعتبار', 'وضعیت هدیه'].contains(f.label);
      }
      if (section == PortalSection.profile) return f.label.contains('کاربر');
      if (section == PortalSection.traffic) {
        return f.label.contains('ترافیک') ||
            f.label.contains('واقعی') ||
            f.label.contains('بروز');
      }
      return !RegExp(r'^\d+ تا \d+$').hasMatch(f.label);
    }).toList();
    for (final f in fields) {
      children.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  w.portal(f.label),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  f.value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (section == PortalSection.reports) {
      children.add(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in [
                'ServiceHistory',
                'GiftHistory',
                'InstallmentHistory',
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(w(r)),
                    selected: report == r,
                    onSelected: (_) {
                      setState(() => report = r);
                      load();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (section == PortalSection.usage) {
      if (usage.isNotEmpty) {
        children.add(
          TextButton.icon(
            onPressed: () {
              usage = {};
              load();
            },
            icon: const Icon(Icons.arrow_back),
            label: Text(w('back')),
          ),
        );
      }
      for (final table in page.tables) {
        final col = table.headers.indexWhere(
          (h) => h.contains('مجموع مصرف واقعی'),
        );
        if (col >= 0) {
          final rows = table.rows
              .where(
                (r) =>
                    r.length > col &&
                    PortalHtmlAdapter.trafficBytes(r[col]) != null,
              )
              .toList();
          if (rows.isNotEmpty) {
            children.add(
              UsageChart(
                title: w(
                  usage['Type'] == 'Daily' ? 'dailyChart' : 'monthlyChart',
                ),
                values: rows
                    .map(
                      (r) =>
                          PortalHtmlAdapter.trafficBytes(r[col])! / 1073741824,
                    )
                    .toList(),
                labels: rows
                    .map(
                      (r) => r.take(usage['Type'] == 'Daily' ? 1 : 2).join('/'),
                    )
                    .toList(),
              ),
            );
          }
        }
      }
      if (page.usageLinks.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              w('drill'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }
      for (final link in page.usageLinks) {
        children.add(
          Card(
            child: ListTile(
              title: Text(link.label.isEmpty ? w('usage') : link.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                usage = link.parameters;
                load();
              },
            ),
          ),
        );
      }
    }
    for (final table in page.tables) {
      children.add(
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                for (final h in table.headers)
                  DataColumn(label: Text(w.portal(h))),
              ],
              rows: [
                for (final row in table.rows)
                  DataRow(
                    cells: [
                      for (var i = 0; i < table.headers.length; i++)
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 230),
                            child: SelectableText(i < row.length ? row[i] : ''),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }
    if (page.isEmpty && page.notice == null) children.add(notice(w('empty')));
    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          w('datesNote'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
    return children;
  }

  Widget notice(String text) => Card(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(text)),
  );
}

class UsageChart extends StatelessWidget {
  const UsageChart({
    super.key,
    required this.title,
    required this.values,
    required this.labels,
  });
  final String title;
  final List<double> values;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(0, math.max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Semantics(
                        label:
                            '${labels[i]}: ${values[i].toStringAsFixed(3)} GiB',
                        child: Tooltip(
                          message:
                              '${labels[i]}: ${values[i].toStringAsFixed(3)} GiB',
                          child: SizedBox(
                            width: 44,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 110,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 22,
                                      height: maxValue == 0
                                          ? 2
                                          : math.max(
                                              2,
                                              100 * values[i] / maxValue,
                                            ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  labels[i],
                                  style: Theme.of(context).textTheme.labelSmall,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
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
