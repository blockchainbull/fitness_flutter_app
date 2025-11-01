// lib/features/notifications/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String? userId;
  static const String backendUrl = 'https://health-ai-backend-i28b.onrender.com';

  @override
  void initState() {
    super.initState();
    _initializeAndLoadNotifications();
  }

  Future<void> _initializeAndLoadNotifications() async {
    await _getUserId();
    if (userId != null) {
      await _loadNotifications();
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please log in again.')),
        );
      }
    }
  }

  Future<void> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getString('user_id');  // FIXED: Changed from 'userId' to 'user_id'
      });
      print('🔍 Notifications: Retrieved user_id from SharedPreferences: $userId');
    } catch (e) {
      print('Error getting user ID: $e');
    }
  }

  Future<void> _loadNotifications() async {
    if (userId == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/notifications/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = data['notifications'] ?? [];
          isLoading = false;
        });
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await http.put(
        Uri.parse('$backendUrl/notifications/$notificationId/read'),
      );
      
      // Update local state
      setState(() {
        final index = notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (userId == null) return;
    
    try {
      await http.put(
        Uri.parse('$backendUrl/notifications/$userId/read-all'),
      );
      
      // Reload notifications
      await _loadNotifications();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  String _getIcon(String type) {
    switch (type) {
      case 'meal':
        return '🍽️';
      case 'water':
        return '💧';
      case 'workout':
      case 'exercise':
        return '💪';
      case 'sleep':
        return '😴';
      case 'weight':
        return '⚖️';
      case 'supplement':
        return '💊';
      default:
        return '📢';
    }
  }

  String _getTimeAgo(String createdAt) {
    final now = DateTime.now();
    final created = DateTime.parse(createdAt);
    final difference = now.difference(created);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Please log in to view notifications',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          final isRead = notification['is_read'] == true;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.white : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead ? Colors.grey.shade200 : Colors.blue.shade200,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.grey.shade100 : Colors.blue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getIcon(notification['type'] ?? 'general'),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              title: Text(
                                notification['title'] ?? '',
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['message'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTimeAgo(notification['created_at']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (!isRead) {
                                  _markAsRead(notification['id']);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}