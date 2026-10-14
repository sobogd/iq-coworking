import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

import 'auth.dart';
import 'harness.dart';
import 'session_screen.dart' show sessionCard;
import 'generated/task.pb.dart' as pb;

class _RepoPicker extends StatefulWidget {
  final Harness harness;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _RepoPicker(
      {required this.harness,
      required this.selected,
      required this.onSelected});

  @override
  State<_RepoPicker> createState() => _RepoPickerState();
}

class _RepoPickerState extends State<_RepoPicker> {
  String _dir = '~';
  String? _home;
  String? _value;
  List<String> _subdirs = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _value = widget.selected;
    _load('~');
  }

  String get _up {
    final i = _dir.lastIndexOf('/');
    return i <= 0 ? '/' : _dir.substring(0, i);
  }

  String _name(String p) => p.split('/').last;

  String? _valid(String? v) {
    if (v == null || v == _dir) return v;
    if (v == 'up') return _home == null || _dir == _home ? null : v;
    if (v == widget.selected) return v;
    return widget.selected;
  }

  Future<void> _load(String p) async {
    setState(() => _busy = true);
    try {
      final d = await widget.harness.listDirs(p);
      if (!mounted) return;
      setState(() {
        _home ??= d.path;
        _dir = d.path;
        _subdirs = d.dirs.toList();
        _busy = false;
        _value = _valid(_value);
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final seen = <String?>{};
    final defs = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: null, child: Text('Без репо')),
      if (sel != null && sel != _dir && !_subdirs.contains(sel))
        DropdownMenuItem(
            value: sel, child: Text('✓ $sel', overflow: TextOverflow.ellipsis)),
      if (_home != null)
        DropdownMenuItem(
            value: _dir,
            child: Text(sel == _dir
                ? '✓ $_dir'
                : 'взять: $_dir',
                overflow: TextOverflow.ellipsis)),
      if (_home != null && _dir != _home)
        const DropdownMenuItem(value: 'up', child: Text('↑ вверх')),
      for (final d in _subdirs)
        DropdownMenuItem(value: d, child: Text(_name(d))),
    ];
    final items = defs.where((it) => seen.add(it.value)).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _value,
          decoration: InputDecoration(
            labelText: 'Репозиторий',
            helperText: _home == null ? null : 'обзор: $_dir',
          ),
          items: items,
          onChanged: _busy
              ? null
              : (v) {
                  setState(() => _value = v);
                  if (v == null) {
                    widget.onSelected(null);
                  } else if (v == 'up') {
                    _load(_up);
                  } else if (v == _dir) {
                    widget.onSelected(_dir);
                  } else {
                    _load(v);
                  }
                },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              sel == null ? 'репо не выбрано' : 'репо: $sel',
              style: TextStyle(
                  fontSize: 12,
                  color: sel == null ? Colors.grey[600] : Colors.teal.shade600),
            ),
          ),
        ),
      ],
    );
  }
}

class SessionsScreen extends StatefulWidget {
  final AuthStore auth;
  final Harness harness;

  const SessionsScreen({super.key, required this.auth, required this.harness});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<pb.Session> _sessions = [];
  String? _error;
  bool _loading = false;
  String? _selectedRepo;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    widget.harness.token = widget.auth.token;
    try {
      await widget.harness.ensureConnected(widget.auth.host);
    } catch (_) {}
    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = _sessions.isEmpty);
    try {
      final r = await widget.harness.listSessions();
      setState(() {
        _sessions = r;
        _error = null;
      });
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unauthenticated) {
        if (mounted) {
          widget.auth.clear();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        }
        return;
      }
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _newSession() async {
    final message = TextEditingController();
    final systemPrompt = TextEditingController();
    String? repo = _selectedRepo;
    String thinking = 'low';
    int ctxTokens = 32768;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Новая сессия',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _RepoPicker(
                harness: widget.harness,
                selected: repo,
                onSelected: (v) => setSheetState(() => repo = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: systemPrompt,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Системный промпт',
                    hintText: 'роли, правила, тон — опционально'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: thinking,
                decoration: const InputDecoration(labelText: 'Мысли модели'),
                items: const [
                  DropdownMenuItem(value: 'off', child: Text('выключены')),
                  DropdownMenuItem(value: 'low', child: Text('low')),
                  DropdownMenuItem(value: 'medium', child: Text('medium')),
                  DropdownMenuItem(value: 'xhigh', child: Text('xhigh')),
                ],
                onChanged: (v) => setSheetState(() => thinking = v ?? 'low'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: ctxTokens,
                decoration: const InputDecoration(labelText: 'Размер контекста'),
                items: const [
                  DropdownMenuItem(value: 16384, child: Text('16k')),
                  DropdownMenuItem(value: 32768, child: Text('32k')),
                  DropdownMenuItem(value: 65536, child: Text('64k')),
                  DropdownMenuItem(value: 131072, child: Text('128k')),
                  DropdownMenuItem(value: 204800, child: Text('204k')),
                ],
                onChanged: (v) => setSheetState(() => ctxTokens = v ?? 32768),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: message,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Первое сообщение'),
                onSubmitted: (_) {
                  if (message.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, message.text.trim());
                  }
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (message.text.trim().isEmpty)
                    ? null
                    : () => Navigator.pop(ctx, message.text.trim()),
                child: const Text('Создать'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      try {
        final s = await widget.harness.createSession(
            result, repo ?? '',
            systemPrompt: systemPrompt.text.trim(),
            thinking: thinking, context: ctxTokens);
        if (!mounted) return;
        await Navigator.of(context)
            .pushNamed('/session', arguments: s.id);
        await _refresh();
      } catch (e) {
        _snack('$e');
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _delete(pb.Session s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить сессию?'),
        content: Text(s.title.isEmpty ? s.id : s.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('Нет')),
          TextButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('Да')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await widget.harness.deleteSession(s.id);
        await _refresh();
      } catch (e) {
        _snack('$e');
      }
    }
  }

  List<pb.Session> get _sorted => _sessions.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сессии'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Новая сессия',
            onPressed: _newSession,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.logout),
            onSelected: (v) async {
              if (v == 'out') {
                widget.auth.clear();
                widget.harness.dispose();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (_) => false);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'out', child: Text('Выйти')),
            ],
          ),
        ],
      ),
      body: _error != null && _sessions.isEmpty
          ? Center(child: Text(_error!))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : sorted.isEmpty
                  ? const Center(child: Text('Сессий нет'))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          final s = sorted[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: sessionCard(
                              s,
                              onTap: () async {
                                await Navigator.of(context)
                                    .pushNamed('/session', arguments: s.id);
                                await _refresh();
                              },
                              onLongPress: () => _delete(s),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
