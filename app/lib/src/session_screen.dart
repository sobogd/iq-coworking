import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth.dart';
import 'harness.dart';
import 'generated/task.pb.dart' as pb;

const idleStatuses = ['IDLE'];
const activeStatuses = ['BUSY'];

String fmtTime(int unix) => unix == 0
    ? '—'
    : DateTime.fromMillisecondsSinceEpoch(unix * 1000)
          .toLocal()
          .toString()
          .substring(0, 16);

Widget sessionCard(
  pb.Session s, {
  required VoidCallback onTap,
  VoidCallback? onLongPress,
}) {
  final active = activeStatuses.contains(s.status);
  return Material(
    color: active ? Colors.indigo.withValues(alpha: 0.08) : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.circle : Icons.circle_outlined,
                  size: 14,
                  color: switch (s.status) {
                    'FAILED' => Colors.redAccent,
                    'STOPPED' => Colors.orange,
                    _ => active ? Colors.indigo : Colors.grey,
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.title.isEmpty ? s.id : s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (s.repo.isNotEmpty) ...[
                  Expanded(
                    child: Text(
                      s.repo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  s.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: switch (s.status) {
                      'FAILED' => Colors.redAccent,
                      'STOPPED' => Colors.orange,
                      _ => Colors.indigo,
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  fmtTime(s.updatedAt.toInt()),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class SessionDetailScreen extends StatefulWidget {
  final AuthStore auth;
  final Harness harness;
  final String id;

  const SessionDetailScreen(
      {super.key,
      required this.auth,
      required this.harness,
      required this.id});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _ReasoningTile extends StatefulWidget {
  final String text;

  const _ReasoningTile({required this.text});

  @override
  State<_ReasoningTile> createState() => _ReasoningTileState();
}

class _ReasoningTileState extends State<_ReasoningTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Row(
            children: [
              Icon(Icons.psychology_outlined, size: 13,
                  color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(_open ? 'мысли ▾' : 'мысли ▸',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 4),
            child: Text(
              widget.text,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  pb.Session? _session;
  pb.Activity? _activity;
  String? _error;
  StreamSubscription? _sub;
  Timer? _poll;
  Timer? _ghostTimer;
  bool _sending = false;
  bool _ghostBusy = false;
  String _ghost = '';
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _list = ScrollController();
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _connect();
    _poll = Timer.periodic(const Duration(milliseconds: 2500), (_) => _tick());
    _input.addListener(_onInputChanged);
  }

  Future<void> _connect() async {
    widget.harness.token = widget.auth.token;
    try {
      await widget.harness.ensureConnected(widget.auth.host);
    } catch (_) {}
    _watch();
    await _load();
  }

  bool get _busy =>
      _session != null && activeStatuses.contains(_session!.status);

  Future<void> _load() async {
    try {
      final s = await widget.harness.getSession(widget.id);
      if (!mounted) return;
      setState(() => _session = s);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    await _fetchActivity();
  }

  Future<void> _watch() async {
    _sub?.cancel();
    try {
      _sub = widget.harness
          .watchSession(widget.id)
          .listen(
            (s) {
              if (!mounted) return;
              setState(() => _session = s);
              _stickToBottom();
            },
            onError: (e) {
              if (mounted) setState(() => _error = '$e');
            },
            onDone: () {
              if (mounted && _busy) _watch();
            },
          );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _fetchActivity() async {
    try {
      final a = await widget.harness.getActivity(widget.id);
      if (!mounted) return;
      setState(() => _activity = a);
      _stickToBottom();
    } catch (_) {}
  }

  void _tick() {
    if (_busy) _fetchActivity();
  }

  void _onInputChanged() {
    _ghostTimer?.cancel();
    final text = _input.text;
    if (text.trim().isEmpty) {
      _ghost = '';
      return;
    }
    _ghostTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted || _ghostBusy) return;
      _ghostBusy = true;
      try {
        final r = await widget.harness.complete(widget.id, text);
        if (!mounted) return;
        setState(() => _ghost = r.text);
      } catch (_) {
        if (mounted) setState(() => _ghost = '');
      } finally {
        _ghostBusy = false;
      }
    });
  }

  void _acceptGhost() {
    if (_ghost.isEmpty) return;
    final pos = _input.selection.baseOffset;
    _input.value = TextEditingValue(
      text:
          _input.text.substring(0, pos) +
          _ghost +
          _input.text.substring(pos),
      selection: TextSelection.collapsed(offset: pos + _ghost.length),
    );
    setState(() => _ghost = '');
    _focus.requestFocus();
  }

  void _dismissGhost() {
    if (_ghost.isNotEmpty) {
      setState(() => _ghost = '');
      _focus.requestFocus();
    }
  }

  bool get _atBottom {
    if (!_list.hasClients) return true;
    final p = _list.position;
    return p.pixels >= p.maxScrollExtent - 60;
  }

  void _stickToBottom() {
    if (!(_follow && _atBottom)) {
      _follow = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_list.hasClients) return;
      _list.jumpTo(_list.position.maxScrollExtent);
    });
  }

  Future<bool> _action(Future Function() fn) async {
    try {
      await fn();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
      return false;
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _sending = true;
    _ghost = '';
    try {
      final ok = await _action(() async {
        final s = await widget.harness.sendMessage(widget.id, text);
        if (mounted) setState(() => _session = s);
      });
      if (ok) {
        _input.clear();
        _fetchActivity();
      }
    } finally {
      _sending = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    _ghostTimer?.cancel();
    _input.dispose();
    _focus.dispose();
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final actMsgs = _activity?.messages ?? const <pb.ActivityMessage>[];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
        if (session == null)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    session.title.isEmpty ? session.id : session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _statusChip(session),
                if (session.thinking.isNotEmpty && session.thinking != 'off') ...[
                  const SizedBox(width: 8),
                  _thinkingChip(session.thinking),
                ],
                if (session.contextTokens != 32768) ...[
                  const SizedBox(width: 8),
                  _ctxChip(session.contextTokens),
                ],
                if (session.repo.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.repo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox.shrink()),
                const SizedBox(width: 12),
                Text(fmtTime(session.createdAt.toInt()),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (session.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                session.error,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.redAccent),
              ),
            ),
          const Divider(height: 24),
          Expanded(
            child: actMsgs.isEmpty
                ? const Center(child: Text('Пока пусто', style: TextStyle(color: Colors.grey)))
                : NotificationListener<UserScrollNotification>(
                    onNotification: (n) {
                      _follow = _atBottom;
                      return false;
                    },
                    child: ListView.builder(
                      controller: _list,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: actMsgs.length,
                      itemBuilder: (context, i) => _actTile(actMsgs[i]),
                    ),
                  ),
          ),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'К списку',
            onPressed: () => Navigator.of(context).pop()),
        title: Text(session?.title.isNotEmpty ?? false
            ? session!.title
            : (session != null ? session.id.substring(0, 8) : 'Сессия')),
        actions: [
          if (_busy)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Остановить',
              onPressed: () =>
                  _action(() => widget.harness.stopSession(widget.id)),
            ),
          if (session != null &&
              (session.status == 'STOPPED' || session.status == 'FAILED'))
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Возобновить',
              onPressed: () =>
                  _action(() => widget.harness.resumeSession(widget.id)),
            ),
          if (session != null && !_busy)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Удалить сессию?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Нет')),
                      TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Да')),
                    ],
                  ),
                );
                if (ok == true) {
                  final done = await _action(
                      () => widget.harness.deleteSession(session.id));
                  if (done && context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 3, child: body),
                const VerticalDivider(width: 1),
                Expanded(flex: 2, child: _inputPanel()),
              ],
            )
          : Column(
              children: [
                Expanded(child: body),
                _inputPanel(),
              ],
            ),
    );
  }

  Widget _statusChip(pb.Session s) {
    final (label, color) = switch (s.status) {
      'BUSY' => ('Выполняется', Colors.indigo),
      'IDLE' => ('Готово', Colors.green),
      'STOPPED' => ('Остановлено', Colors.orange),
      'FAILED' => ('Ошибка', Colors.redAccent),
      _ => (s.status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            s.status == 'IDLE'
                ? Icons.check_circle
                : s.status == 'FAILED'
                    ? Icons.error
                    : Icons.hourglass_top,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(label,
              style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _thinkingChip(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology_outlined, size: 13, color: Colors.teal),
          const SizedBox(width: 5),
          Text('✦ $level',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _ctxChip(int tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('${(tokens / 1024).round()}k',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _actTile(pb.ActivityMessage m) {
    final (icon, color) = switch (m.role) {
      'assistant' => (Icons.smart_toy, Colors.indigo),
      'user' => (Icons.person, Colors.green),
      _ => (Icons.build_circle, Colors.grey),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(m.role,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          if (m.toolCalls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tc in m.toolCalls)
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 12,
                            color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (m.reasoning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 20),
              child: _ReasoningTile(text: m.reasoning),
            ),
          if (m.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 20),
              child: Text(
                m.content,
                selectable: true,
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Focus(
                  focusNode: _focus,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
                      _acceptGhost();
                      return KeyEventResult.handled;
                    }
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                      _dismissGhost();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _input,
                    enabled: !_sending,
                    maxLines: 1,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _busy
                          ? 'Сообщение (отправится в очередь)'
                          : 'Сообщение (Enter — отправить)',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: _sending ? null : _send,
              ),
            ],
          ),
          if (_ghost.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '⌥ $_ghost',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tab — принять · Esc — отбросить',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
