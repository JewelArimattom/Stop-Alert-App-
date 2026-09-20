import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioService _audioService = AudioService();
  bool _isPreviewPlaying = false;

  @override
  void dispose() {
    _audioService.stopPreview();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile(SettingsProvider settings) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        await settings.setCustomAlarm(path, name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alarm sound set to "$name"'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _togglePreview(String? path) async {
    if (_isPreviewPlaying) {
      await _audioService.stopPreview();
      setState(() => _isPreviewPlaying = false);
    } else {
      setState(() => _isPreviewPlaying = true);
      await _audioService.playPreview(path);
      // Automatically reset preview state after 8 seconds if continuous
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _isPreviewPlaying) {
          _audioService.stopPreview();
          setState(() => _isPreviewPlaying = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildSectionHeader('Alert Distances'),
                      const SizedBox(height: 12),
                      _buildDistanceSlider(
                        icon: Icons.notifications_outlined,
                        label: 'Notification Alert',
                        description: 'First notification when approaching',
                        value: settings.alertNotifyDistance,
                        min: 500,
                        max: 5000,
                        color: AppColors.info,
                        onChanged: settings.setAlertNotifyDistance,
                      ),
                      const SizedBox(height: 12),
                      _buildDistanceSlider(
                        icon: Icons.volume_up_rounded,
                        label: 'Sound Alert',
                        description: 'Play sound when getting close',
                        value: settings.alertSoundDistance,
                        min: 200,
                        max: 2000,
                        color: AppColors.warning,
                        onChanged: settings.setAlertSoundDistance,
                      ),
                      const SizedBox(height: 12),
                      _buildDistanceSlider(
                        icon: Icons.alarm_rounded,
                        label: 'Continuous Alarm',
                        description: 'Full alarm when destination is reached',
                        value: settings.alertAlarmDistance,
                        min: 50,
                        max: 1000,
                        color: AppColors.danger,
                        onChanged: settings.setAlertAlarmDistance,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Alarm Sound & Music'),
                      const SizedBox(height: 12),
                      _buildAlarmSoundCard(settings),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Preferences'),
                      const SizedBox(height: 12),
                      _buildSwitchTile(
                        icon: Icons.vibration_rounded,
                        label: 'Vibration',
                        description: 'Vibrate with alerts and alarms',
                        value: settings.vibrationEnabled,
                        onChanged: settings.setVibrationEnabled,
                      ),
                      const SizedBox(height: 10),
                      _buildSwitchTile(
                        icon: Icons.music_note_rounded,
                        label: 'Sound Alerts',
                        description: 'Play alert sounds when tracking',
                        value: settings.soundEnabled,
                        onChanged: settings.setSoundEnabled,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('About'),
                      const SizedBox(height: 12),
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmSoundCard(SettingsProvider settings) {
    final hasCustom = settings.hasCustomAlarm;
    final soundName = hasCustom
        ? (settings.customAlarmName ?? 'Custom Sound')
        : 'Default Ringtone (alarm.wav)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasCustom ? AppColors.primary.withOpacity(0.4) : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.library_music_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Alarm Ringtone',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (hasCustom) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CUSTOM',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      soundName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasCustom ? AppColors.primaryLight : AppColors.textMuted,
                        fontWeight: hasCustom ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Choose local audio file button
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickAudioFile(settings),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Pick Local File',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Preview button
              GestureDetector(
                onTap: () => _togglePreview(settings.customAlarmPath),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _isPreviewPlaying ? AppColors.danger.withOpacity(0.15) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPreviewPlaying ? AppColors.danger : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPreviewPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: _isPreviewPlaying ? AppColors.danger : AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPreviewPlaying ? 'Stop' : 'Test',
                        style: TextStyle(
                          color: _isPreviewPlaying ? AppColors.danger : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Reset to default button (if custom set)
              if (hasCustom) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    if (_isPreviewPlaying) {
                      await _audioService.stopPreview();
                      setState(() => _isPreviewPlaying = false);
                    }
                    await settings.clearCustomAlarm();
                  },
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.restore_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceSlider({
    required IconData icon,
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required Color color,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value >= 1000
                      ? '${(value / 1000).toStringAsFixed(1)} km'
                      : '${value.toInt()} m',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceLight,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'StopAlert Premium',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Version 2.0.0 • Pro Geofence GPS',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Smart GPS wake-up alarms for trains, buses, and travel. Background service only activates during active tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
