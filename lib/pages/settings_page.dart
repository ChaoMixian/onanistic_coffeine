// lib/pages/settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../main.dart';
import '../services/options_service.dart';
import 'options_management_page.dart';


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _dailyReminder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置'), centerTitle: true),
      body: ListView(
        children: [
          _buildSectionHeader('通知设置'),
          SwitchListTile(
            title: Text('启用通知'),
            subtitle: Text('接收应用相关通知'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('每日提醒'),
            subtitle: Text('每天提醒记录健康习惯'),
            value: _dailyReminder,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _dailyReminder = value;
                    });
                  }
                : null,
          ),
          Divider(),

          _buildSectionHeader('显示设置'),
          SwitchListTile(
            title: Text('深色模式'),
            subtitle: Text('使用深色主题'),
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (value) {
              setState(() {
                themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
          Divider(),

          _buildSectionHeader('选项管理'),
          ListTile(
            leading: Icon(Icons.category_outlined),
            title: Text('管理事件类型'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _navigateToManagementPage(
              title: '管理事件类型',
              optionsNotifier: OptionsService().eventTypes,
              onUpdate: OptionsService().updateEventTypes,
              onReset: OptionsService().resetEventTypes,
              onAdd: OptionsService().addEventType,
            ),
          ),
          ListTile(
            leading: Icon(Icons.psychology_alt_outlined),
            title: Text('管理主要原因'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _navigateToManagementPage(
              title: '管理主要原因',
              optionsNotifier: OptionsService().reasons,
              onUpdate: OptionsService().updateReasons,
              onReset: OptionsService().resetReasons,
              onAdd: OptionsService().addReason,
            ),
          ),
          Divider(),

          _buildSectionHeader('数据管理'),
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('备份数据'),
            subtitle: Text('将数据备份为本地文件'),
            trailing: Icon(Icons.chevron_right),
            onTap: _shareDatabase,
          ),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('恢复数据'),
            subtitle: Text('从备份文件恢复数据'),
            trailing: Icon(Icons.chevron_right),
            onTap: _restoreDatabase,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('清除所有数据', style: TextStyle(color: Colors.red)),
            subtitle: Text('永久删除所有记录数据'),
            trailing: Icon(Icons.chevron_right),
            onTap: _showDeleteConfirmDialog,
          ),
          Divider(),

          _buildSectionHeader('关于'),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('关于应用'),
            subtitle: Text('版本 1.0.0'),
            trailing: Icon(Icons.chevron_right),
            onTap: _showAboutDialog,
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('隐私政策'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _showDialog('隐私政策', '我们重视您的隐私，所有数据仅存储在本地设备上。');
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('使用帮助'),
            trailing: Icon(Icons.chevron_right),
            onTap: _showHelpDialog,
          ),
        ],
      ),
    );
  }
  
  void _navigateToManagementPage({
    required String title,
    required ValueNotifier<List<String>> optionsNotifier,
    required Future<void> Function(List<String>) onUpdate,
    required Future<void> Function() onReset,
    required Future<void> Function(String) onAdd,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptionsManagementPage(
          title: title,
          optionsNotifier: optionsNotifier,
          onUpdate: onUpdate,
          onReset: onReset,
          onAdd: onAdd,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("确定"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("确认删除"),
        content: Text("确定要永久删除所有记录吗？此操作不可撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllData();
            },
            child: Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteAll();
      _showDialog("清除完成", "所有数据已删除。");
    } catch (e) {
      _showDialog("清除失败", "删除数据时发生错误: ${e.toString()}");
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '手冲咖啡',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Mixian Chao',
    );
  }

  void _showHelpDialog() {
    _showDialog("使用帮助", "在首页点击“记录一次”可添加新记录。\n\n您可以在分析页面查看打飞机频率与感受趋势。");
  }

  Future<void> _shareDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/health_habit_tracker.db');

      if (!await dbFile.exists()) {
        _showDialog('分享失败', '数据库文件不存在，请先确保有数据可备份。');
        return;
      }

      await Share.shareXFiles([XFile(dbFile.path)], text: '我的手冲咖啡数据备份');
    } catch (e) {
      _showDialog('分享失败', '无法分享数据库文件: ${e.toString()}');
    }
  }

  Future<void> _restoreDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final dbPath = await getDatabasesPath();
        final targetPath = '$dbPath/health_habit_tracker.db';

        await DatabaseHelper.instance.close();
        
        if (await File(targetPath).exists()) {
          await File(targetPath).delete();
        }
        await pickedFile.copy(targetPath);
        
        await DatabaseHelper.instance.resetDatabaseInstance();
        await DatabaseHelper.instance.database;

        // 重新初始化选项服务以加载新数据库中的数据
        await OptionsService().init();
        
        _showDialog('恢复成功', '数据库已恢复，建议重启应用以确保所有数据正确加载。');
      } else {
        _showDialog('恢复取消', '未选择任何文件。');
      }
    } catch (e) {
      _showDialog('恢复失败', '恢复数据时发生错误: ${e.toString()}');
    }
  }
}