import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/providers/app_state.dart';
import '../routes/route_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Attempting login for user: ${_usernameController.text}');
      await ref.read(appStateProvider.notifier).login(
        _usernameController.text,
        _passwordController.text,
      );
      debugPrint('Login successful');
      
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      }
    } on DioException catch (e) {
      debugPrint('DioException during login: ${e.message}');
      if (mounted) {
        String message;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          message = '连接服务器失败，请检查网络连接';
        } else if (e.response?.statusCode == 422) {
          final errors = e.response?.data?['detail'] as List?;
          if (errors != null && errors.isNotEmpty) {
            message = errors.map((e) => e['msg']).join('\n');
          } else {
            message = '输入验证失败，请检查输入';
          }
        } else if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
          message = e.response?.data?['detail'] ?? '用户名或密码错误';
        } else {
          message = '登录失败: ${e.message}';
        }
        _showError(message);
      }
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      if (mounted) {
        _showError('登录失败: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '登录',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[900]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[900]!, width: 1),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[100]),
                ),
              ),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '用户名',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                if (value.length < 3 || value.length > 20) {
                  return '用户名长度必须在3-20个字符之间';
                }
                if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                  return '用户名只能包含字母、数字、下划线和连字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '密码',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 8) {
                  return '密码长度不能少于8个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pushNamed(context, Routes.register);
                    },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('没有账号？立即注册'),
            ),
          ],
        ),
      ),
    );
  }
}
