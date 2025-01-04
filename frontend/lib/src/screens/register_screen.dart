import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/providers/app_state.dart';
import '../routes/route_constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Attempting registration for user: ${_usernameController.text}');
      await ref.read(appStateProvider.notifier).register(
        _usernameController.text,
        _passwordController.text,
      );
      debugPrint('Registration successful');
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.home);
      }
    } on DioException catch (e) {
      debugPrint('DioException during registration: ${e.message}');
      if (mounted) {
        String message;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          message = '连接服务器失败，请检查网络连接';
        } else if (e.response?.statusCode == 400) {
          if (e.response?.data?['detail']?.contains('already exists') ?? false) {
            message = '用户名已存在';
          } else {
            message = e.response?.data?['detail'] ?? '注册失败，请检查输入';
          }
        } else {
          message = '注册失败: ${e.message}';
        }
        _showError(message);
      }
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      if (mounted) {
        _showError('注册失败: ${e.toString()}');
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
          '注册',
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
                if (value.length < 3) {
                  return '用户名至少需要3个字符';
                }
                if (value.length > 20) {
                  return '用户名不能超过20个字符';
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
                  return '密码至少需要8个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
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
                      '注册',
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
                      Navigator.pushReplacementNamed(context, Routes.login);
                    },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('已有账号？立即登录'),
            ),
          ],
        ),
      ),
    );
  }
}
