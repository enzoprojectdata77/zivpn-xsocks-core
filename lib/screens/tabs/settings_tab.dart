import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../app_colors.dart';
import '../../repositories/backup_repository.dart';
import '../../services/autopilot_service.dart';
import '../app_selector_page.dart';

class SettingsTab extends StatefulWidget {
  final VoidCallback onCheckUpdate;
  final VoidCallback? onRestoreSuccess;

  const SettingsTab({
    super.key, 
    required this.onCheckUpdate,
    this.onRestoreSuccess,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _mtuCtrl = TextEditingController();
  final _pingTargetCtrl = TextEditingController();
  final _pingIntervalCtrl = TextEditingController();
  final _udpgwPortCtrl = TextEditingController();
  final _udpgwMaxConnCtrl = TextEditingController();
  final _udpgwBufSizeCtrl = TextEditingController();
  final _dnsCtrl = TextEditingController();
  final _appsListCtrl = TextEditingController();
  final _tcpSndBufCtrl = TextEditingController();
  final _tcpWndCtrl = TextEditingController();
  final _socksBufCtrl = TextEditingController();
  final _maxFailCtrl = TextEditingController();
  final _airplaneDelayCtrl = TextEditingController();
  final _recoveryWaitCtrl = TextEditingController();
  final _pingTimeoutCtrl = TextEditingController();
  final _stabilizerSizeCtrl = TextEditingController();

  bool _cpuWakelock = false;
  bool _enableUdpgw = true;
  bool _autoReset = false;
  bool _enableStabilizer = false;
  bool _filterApps = false;
  bool _bypassMode = false;
  String _logLevel = "info";
  double _coreCount = 4.0;
  String _appVersion = "Unknown";
  
  final _backupRepo = BackupRepository();
  final _autoPilot = AutoPilotService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _openAppSelector() async {
    final currentList = _appsListCtrl.text
        .split("\n")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AppSelectorPage(initialSelected: currentList),
      ),
    );

    if (result != null) {
      setState(() {
        _appsListCtrl.text = result.join("\n");
      });
    }
  }

  Future<void> _handleBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Creating backup...")));
    final file = await _backupRepo.createBackup();
    if (file != null && mounted) {
      await Share.shareXFiles([XFile(file.path)], text: "MiniZIVPN Config Backup");
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup failed")));
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result != null && result.files.single.path != null) {
      final success = await _backupRepo.restoreBackup(File(result.files.single.path!));
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restore successful.")));
        _loadSettings();
        widget.onRestoreSuccess?.call();
      }
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = "v${info.version}");
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mtuCtrl.text = (prefs.getInt('mtu') ?? 1500).toString();
      _pingTargetCtrl.text = prefs.getString('ping_target') ?? "http://www.gstatic.com/generate_204";
      _pingIntervalCtrl.text = (prefs.getInt('ping_interval') ?? 3).toString();
      _udpgwPortCtrl.text = prefs.getString('udpgw_port') ?? "7300";
      _udpgwMaxConnCtrl.text = prefs.getString('udpgw_max_connections') ?? "512";
      _udpgwBufSizeCtrl.text = prefs.getString('udpgw_buffer_size') ?? "32";
      _dnsCtrl.text = prefs.getString('upstream_dns') ?? "208.67.222.222";
      _appsListCtrl.text = prefs.getString('apps_list') ?? "";
      _tcpSndBufCtrl.text = prefs.getString('tcp_snd_buf') ?? "65535";
      _tcpWndCtrl.text = prefs.getString('tcp_wnd') ?? "65535";
      _socksBufCtrl.text = prefs.getString('socks_buf') ?? "65536";
      _maxFailCtrl.text = (prefs.getInt('max_fail_count') ?? 3).toString();
      _airplaneDelayCtrl.text = (prefs.getInt('airplane_delay') ?? 2).toString();
      _recoveryWaitCtrl.text = (prefs.getInt('recovery_wait') ?? 10).toString();
      _pingTimeoutCtrl.text = (prefs.getInt('ping_timeout') ?? 5).toString();
      _stabilizerSizeCtrl.text = (prefs.getInt('stabilizer_size') ?? 1).toString();
      
      _cpuWakelock = prefs.getBool('cpu_wakelock') ?? false;
      _enableUdpgw = prefs.getBool('enable_udpgw') ?? true;
      _autoReset = prefs.getBool('auto_reset') ?? false;
      _enableStabilizer = prefs.getBool('enable_stabilizer') ?? false;
      _filterApps = prefs.getBool('filter_apps') ?? false;
      _bypassMode = prefs.getBool('bypass_mode') ?? false;
      _logLevel = prefs.getString('log_level') ?? "info";
      _coreCount = (prefs.getInt('core_count') ?? 4).toDouble();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String val(TextEditingController c, String d) => c.text.isEmpty ? d : c.text;

    await prefs.setInt('mtu', int.tryParse(val(_mtuCtrl, "1500")) ?? 1500);
    await prefs.setString('ping_target', val(_pingTargetCtrl, "http://www.gstatic.com/generate_204"));
    await prefs.setInt('ping_interval', int.tryParse(val(_pingIntervalCtrl, "3")) ?? 3);
    await prefs.setString('udpgw_port', val(_udpgwPortCtrl, "7300"));
    await prefs.setString('udpgw_max_connections', val(_udpgwMaxConnCtrl, "512"));
    await prefs.setString('udpgw_buffer_size', val(_udpgwBufSizeCtrl, "32"));
    await prefs.setString('upstream_dns', val(_dnsCtrl, "208.67.222.222"));
    await prefs.setString('apps_list', _appsListCtrl.text);
    await prefs.setString('tcp_snd_buf', val(_tcpSndBufCtrl, "65535"));
    await prefs.setString('tcp_wnd', val(_tcpWndCtrl, "65535"));
    await prefs.setString('socks_buf', val(_socksBufCtrl, "65536"));
    await prefs.setInt('max_fail_count', int.tryParse(val(_maxFailCtrl, "3")) ?? 3);
    await prefs.setInt('airplane_delay', int.tryParse(val(_airplaneDelayCtrl, "2")) ?? 2);
    await prefs.setInt('recovery_wait', int.tryParse(val(_recoveryWaitCtrl, "10")) ?? 10);
    await prefs.setInt('ping_timeout', int.tryParse(val(_pingTimeoutCtrl, "5")) ?? 5);
    await prefs.setInt('stabilizer_size', int.tryParse(val(_stabilizerSizeCtrl, "1")) ?? 1);
    
    await prefs.setBool('cpu_wakelock', _cpuWakelock);
    await prefs.setBool('enable_udpgw', _enableUdpgw);
    await prefs.setBool('auto_reset', _autoReset);
    await prefs.setBool('enable_stabilizer', _enableStabilizer);
    await prefs.setBool('filter_apps', _filterApps);
    await prefs.setBool('bypass_mode', _bypassMode);
    await prefs.setString('log_level', _logLevel);
    await prefs.setInt('core_count', _coreCount.toInt());

    _loadSettings();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Saved")));
  }

  Future<void> _handleSignalReset() async {
    final available = await _autoPilot.isShizukuAvailable();
    if (!available) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shizuku is not running.")));
      return;
    }
    final granted = await _autoPilot.checkAndRequestPermission();
    if (!granted) return;

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resetting signal...")));
    try {
      await _autoPilot.manualReset();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Core Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTextInput(_mtuCtrl, "MTU (Default: 1500)", Icons.settings_ethernet),
                const Divider(),
                const ListTile(title: Text("UDP Forwarding", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                SwitchListTile(
                  title: const Text("Forward UDP"),
                  value: _enableUdpgw,
                  onChanged: (val) => setState(() => _enableUdpgw = val),
                ),
                if (_enableUdpgw) ...[
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_udpgwPortCtrl, "Udp Gateway Port", Icons.door_sliding)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_udpgwMaxConnCtrl, "Max UDP Connections", Icons.connect_without_contact)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_udpgwBufSizeCtrl, "UDP Buffer (Packets)", Icons.shopping_bag)),
                ],
                const Divider(),
                const ListTile(title: Text("Ping & AutoPilot", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_pingIntervalCtrl, "Check Interval (sec)", Icons.timer)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_pingTargetCtrl, "Target Ping (URL/IP)", Icons.network_check)),
                ListTile(
                  leading: const Icon(Icons.signal_cellular_alt_sharp),
                  title: const Text("Manual Signal Reset"),
                  subtitle: const Text("Toggle Airplane Mode via Shizuku"),
                  trailing: const Icon(Icons.refresh, color: AppColors.primary),
                  onTap: _handleSignalReset,
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text("Test Shizuku Service"),
                  onTap: () async {
                    final available = await _autoPilot.isShizukuAvailable();
                    if (!available) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shizuku NOT Available")));
                      return;
                    }
                    final granted = await _autoPilot.checkAndRequestPermission();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(granted ? "Shizuku Ready" : "Permission Denied")));
                  },
                ),
                SwitchListTile(
                  title: const Text("Auto Signal Reset"),
                  value: _autoReset,
                  onChanged: (val) => setState(() => _autoReset = val),
                ),
                if (_autoReset) ...[
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_maxFailCtrl, "Max Failures", Icons.warning_amber)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_airplaneDelayCtrl, "Airplane Duration (sec)", Icons.timer_off)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_recoveryWaitCtrl, "Recovery Wait (sec)", Icons.hourglass_empty)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_pingTimeoutCtrl, "Ping Timeout (sec)", Icons.timer_10)),
                  SwitchListTile(
                    title: const Text("Enable Stabilizer"),
                    value: _enableStabilizer,
                    onChanged: (val) => setState(() => _enableStabilizer = val),
                  ),
                  if (_enableStabilizer)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_stabilizerSizeCtrl, "Stabilizer Size (MB)", Icons.download)),
                ],
                const Divider(),
                const ListTile(title: Text("Apps Filter", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                SwitchListTile(
                  title: const Text("Filter Apps"),
                  value: _filterApps,
                  onChanged: (val) => setState(() => _filterApps = val),
                ),
                SwitchListTile(
                  title: const Text("Bypass Mode"),
                  value: _bypassMode,
                  onChanged: (val) => setState(() => _bypassMode = val),
                ),
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: const Text("Select Apps"),
                  onTap: _openAppSelector,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _appsListCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Apps List (Package names)",
                      prefixIcon: const Icon(Icons.list),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                  ),
                ),
                const Divider(),
                const ListTile(title: Text("Advanced", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                _buildSliderSection(),
                SwitchListTile(
                  title: const Text("CPU Wakelock"),
                  value: _cpuWakelock,
                  onChanged: (val) => setState(() => _cpuWakelock = val),
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_tcpSndBufCtrl, "TCP Send Buffer", Icons.upload_file)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_tcpWndCtrl, "TCP Window Size", Icons.download_for_offline)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_socksBufCtrl, "SOCKS Buffer", Icons.memory)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildTextInput(_dnsCtrl, "Upstream DNS", Icons.dns)),
                _buildDropdownTile("Log Level", "Verbosity", _logLevel, ["debug", "info", "error", "silent"], (val) => setState(() => _logLevel = val!)),
                const Divider(),
                ListTile(leading: const Icon(Icons.cloud_download_outlined), title: const Text("Backup Configuration"), onTap: _handleBackup),
                ListTile(leading: const Icon(Icons.restore_page_outlined), title: const Text("Restore Configuration"), onTap: _handleRestore),
                ListTile(
                  leading: const Icon(Icons.system_update), 
                  title: const Text("Check for Updates"), 
                  subtitle: Text("Current: $_appVersion"), 
                  onTap: widget.onCheckUpdate
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _saveSettings,
          icon: const Icon(Icons.save),
          label: const Text("Save Configuration"),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
        )
      ],
    );
  }

  Widget _buildTextInput(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.card,
      ),
    );
  }

  Widget _buildSliderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("Hysteria Cores: ${_coreCount.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold))),
        Slider(value: _coreCount, min: 1, max: 8, divisions: 7, label: "${_coreCount.toInt()} Cores", onChanged: (val) => setState(() => _coreCount = val)),
      ],
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String value, List<String> items, ValueChanged<String?> onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toUpperCase()))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
