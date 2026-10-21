import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:advanced_background_locator/advanced_background_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'file_manager.dart';
import 'location_callback_handler.dart';
import 'location_service_repository.dart';

void main() => runApp(const MyApp());

const Color _brandColor = Color(0xFF0B3D91);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _brandColor, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konum Takibi',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const TrackerPage(),
    );
  }
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final ReceivePort port = ReceivePort();
  String logStr = '';
  bool isRunning = false;
  bool isBusy = false;
  LocationDto? lastLocation;

  @override
  void initState() {
    super.initState();

    // Arka planda çalışan izleyici için port kaydını kaldır
    if (IsolateNameServer.lookupPortByName(LocationServiceRepository.isolateName) != null) {
      IsolateNameServer.removePortNameMapping(LocationServiceRepository.isolateName);
    }

    // Yeni port kaydını oluştur
    IsolateNameServer.registerPortWithName(port.sendPort, LocationServiceRepository.isolateName);

    port.listen((dynamic data) async {
      debugPrint('Data: $data');
      await updateUI(data);
    }, onError: (error) {
      debugPrint('Error: $error');
    });

    initPlatformState();
  }

  Future<void> updateUI(dynamic data) async {
    final log = await FileManager.readLogFile();
    final LocationDto? locationDto = data is Map ? LocationDto.fromJson(data) : null;
    if (locationDto != null) {
      await _updateNotificationText(locationDto);
    }
    if (!mounted) return;

    setState(() {
      if (locationDto != null) {
        lastLocation = locationDto;
      }
      logStr = log;
    });
  }

  Future<void> _updateNotificationText(LocationDto data) async {
    await AdvancedBackgroundLocator.updateNotificationText(
      title: 'Konum takibi aktif',
      msg: 'Son güncelleme: ${_formatTime(DateTime.now())}',
      bigMsg: '${data.latitude.toStringAsFixed(5)}, ${data.longitude.toStringAsFixed(5)}',
    );
  }

  Future<void> initPlatformState() async {
    await AdvancedBackgroundLocator.initialize();
    final log = await FileManager.readLogFile();
    final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
    if (!mounted) return;
    setState(() {
      logStr = log;
      isRunning = isRunningResp;
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(LocationServiceRepository.isolateName);
    port.close();
    super.dispose();
  }

  Future<void> onStop() async {
    setState(() => isBusy = true);
    await AdvancedBackgroundLocator.unRegisterLocationUpdate();
    final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
    if (!mounted) return;
    setState(() {
      isRunning = isRunningResp;
      isBusy = false;
    });
  }

  Future<void> _onStart() async {
    setState(() => isBusy = true);
    try {
      if (!await _checkLocationPermission()) {
        _showMessage('Konum izni verilmedi.');
        return;
      }
      await _startLocator();
      final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
      if (!mounted) return;
      setState(() {
        isRunning = isRunningResp;
        lastLocation = null;
      });
    } on PlatformException catch (e) {
      _showMessage(e.message ?? e.code);
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> _clearLog() async {
    await FileManager.clearLogFile();
    if (!mounted) return;
    setState(() => logStr = '');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Requests foreground location first; background ("Allow all the time") must be
  /// requested separately on Android 11+ and iOS. Background access is optional:
  /// tracking still works while the foreground service notification is shown.
  Future<bool> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      return false;
    }

    // Android 13+: without this the foreground service notification is hidden.
    await Permission.notification.request();
    await Permission.locationAlways.request();
    return true;
  }

  Future<void> _startLocator() async {
    final data = {'countInit': 1};
    await AdvancedBackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      iosSettings: const IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 0,
        stopWithTerminate: true,
      ),
      autoStop: false,
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 3,
        distanceFilter: 0,
        client: LocationClient.android,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Konum takibi',
          notificationTitle: 'Konum takibi aktif',
          notificationMsg: 'Konumunuz arka planda kaydediliyor',
          notificationBigMsg: 'Uygulama kapalıyken de rotanızın kaydedilmesi için arka plan konumu açık.',
          notificationIconColor: _brandColor,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _LogEntry.parse(logStr);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konum Takibi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text('Arka plan konum servisi', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Kaydı temizle',
            onPressed: entries.isEmpty ? null : _clearLog,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _StatusCard(isRunning: isRunning),
            const SizedBox(height: 16),
            _ActionButton(isRunning: isRunning, isBusy: isBusy, onStart: _onStart, onStop: onStop),
            const SizedBox(height: 28),
            const _SectionHeader(title: 'Son konum'),
            const SizedBox(height: 8),
            _LocationCard(location: lastLocation, isRunning: isRunning),
            const SizedBox(height: 28),
            _SectionHeader(title: 'Etkinlik kaydı', trailing: entries.isEmpty ? null : '${entries.length} kayıt'),
            const SizedBox(height: 8),
            _LogCard(entries: entries),
            const SizedBox(height: 20),
            Text(
              'Aralık 3 sn  ·  Doğruluk: Navigasyon  ·  İstemci: Android',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

String _formatTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color accent = isRunning ? const Color(0xFF1B873F) : scheme.outline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRunning ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isRunning ? Icons.my_location : Icons.location_disabled_outlined,
                color: isRunning ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRunning ? 'Takip aktif' : 'Takip kapalı',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRunning ? 'Uygulama arka plandayken de konum kaydediliyor.' : 'Konum kaydı için takibi başlatın.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    isRunning ? 'Canlı' : 'Pasif',
                    style: theme.textTheme.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w600),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.isRunning, required this.isBusy, required this.onStart, required this.onStop});

  final bool isRunning;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget icon = isBusy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: isRunning ? scheme.onError : scheme.onPrimary),
          )
        : Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded);

    return FilledButton.icon(
      onPressed: isBusy ? null : (isRunning ? onStop : onStart),
      style: isRunning ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null,
      icon: icon,
      label: Text(isRunning ? 'Takibi durdur' : 'Takibi başlat'),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location, required this.isRunning});

  final LocationDto? location;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final loc = location;
    if (loc == null) {
      return _EmptyCard(
        icon: Icons.satellite_alt_outlined,
        message: isRunning ? 'İlk konum bekleniyor…' : 'Henüz konum alınmadı.',
      );
    }

    final time = DateTime.fromMillisecondsSinceEpoch(loc.time.toInt());
    final metrics = <(String, String)>[
      ('Enlem', loc.latitude.toStringAsFixed(5)),
      ('Boylam', loc.longitude.toStringAsFixed(5)),
      ('Doğruluk', '± ${loc.accuracy.toStringAsFixed(0)} m'),
      ('Hız', '${(loc.speed * 3.6).toStringAsFixed(1)} km/sa'),
      ('Yükseklik', '${loc.altitude.toStringAsFixed(0)} m'),
      ('Zaman', _formatTime(time)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var row = 0; row < metrics.length; row += 2) ...[
              if (row > 0) const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _Metric(label: metrics[row].$1, value: metrics[row].$2)),
                  const SizedBox(width: 16),
                  Expanded(child: _Metric(label: metrics[row + 1].$1, value: metrics[row + 1].$2)),
                ],
              ),
            ],
            if (loc.isMocked || loc.provider.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Kaynak: ${loc.provider.isEmpty ? '-' : loc.provider}${loc.isMocked ? '  ·  Sahte konum' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _LogEntry {
  const _LogEntry({required this.title, required this.subtitle, required this.kind});

  final String title;
  final String subtitle;
  final _LogKind kind;

  static final RegExp _positionLine = RegExp(r'^(-?\d+) : (\S+) --> (\S+) (\S+)');

  /// Parses the example's log file (newest first).
  static List<_LogEntry> parse(String log) {
    final entries = <_LogEntry>[];
    for (final raw in log.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('---')) continue;
      if (line.startsWith('start:')) {
        entries.add(_LogEntry(title: 'Oturum başladı', subtitle: line.substring(6).trim(), kind: _LogKind.start));
      } else if (line.startsWith('end:')) {
        entries.add(_LogEntry(title: 'Oturum bitti', subtitle: line.substring(4).trim(), kind: _LogKind.end));
      } else {
        final match = _positionLine.firstMatch(line);
        if (match == null) continue;
        entries.add(_LogEntry(
          title: '${match.group(3)}, ${match.group(4)}',
          subtitle: '#${match.group(1)}  ·  ${match.group(2)}',
          kind: _LogKind.position,
        ));
      }
    }
    return entries.reversed.toList();
  }
}

enum _LogKind { start, end, position }

class _LogCard extends StatelessWidget {
  const _LogCard({required this.entries});

  static const int _maxVisible = 50;

  final List<_LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyCard(icon: Icons.receipt_long_outlined, message: 'Kayıt yok.');
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visible = entries.take(_maxVisible).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: scheme.outlineVariant),
            ListTile(
              dense: true,
              leading: Icon(
                switch (visible[i].kind) {
                  _LogKind.start => Icons.play_circle_outline,
                  _LogKind.end => Icons.stop_circle_outlined,
                  _LogKind.position => Icons.place_outlined,
                },
                color: visible[i].kind == _LogKind.position ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Text(
                visible[i].title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: visible[i].kind == _LogKind.position ? FontWeight.w500 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              subtitle: Text(visible[i].subtitle),
            ),
          ],
          if (entries.length > _maxVisible)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '+${entries.length - _maxVisible} eski kayıt',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: scheme.outline),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
