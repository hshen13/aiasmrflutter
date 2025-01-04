import 'package:flutter/material.dart';
import '../config/env_config.dart';

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({Key? key}) : super(key: key);

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await EnvConfig.testConnection();
      setState(() {
        _isConnected = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
        _error = EnvConfig.networkErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('测试连接'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '服务器地址: ${EnvConfig.apiBaseUrl}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error != null)
              Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else if (_isConnected)
              Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '连接成功',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                _isLoading ? '测试中...' : '测试连接',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
