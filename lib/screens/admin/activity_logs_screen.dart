// lib/screens/admin/activity_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/admin_management_controller.dart';
import '../../models/admin_activity_log.dart';
import '../../config/theme.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final AdminManagementController _managementController =
      Get.find<AdminManagementController>();

  // 필터링 옵션
  String? _selectedAdmin;
  String? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _managementController.loadActivityLogs(
      adminId: _selectedAdmin,
      action: _selectedAction,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 활동 로그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;

          return Obx(() {
            if (_managementController.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_managementController.activityLogs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '활동 로그가 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // 현재 필터 표시
                if (_selectedAdmin != null ||
                    _selectedAction != null ||
                    _startDate != null ||
                    _endDate != null)
                  _buildActiveFilters(),

                // 로그 목록
                Expanded(
                  child: isSmallScreen
                      ? _buildMobileLogList()
                      : _buildDesktopLogList(),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          const Text(
            '필터:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_selectedAdmin != null)
                  _buildFilterChip('관리자: $_selectedAdmin', () {
                    setState(() {
                      _selectedAdmin = null;
                    });
                    _loadLogs();
                  }),
                if (_selectedAction != null)
                  _buildFilterChip(
                      '작업: ${_getActionDisplayName(_selectedAction!)}', () {
                    setState(() {
                      _selectedAction = null;
                    });
                    _loadLogs();
                  }),
                if (_startDate != null)
                  _buildFilterChip(
                    '시작일: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
                    () {
                      setState(() {
                        _startDate = null;
                      });
                      _loadLogs();
                    },
                  ),
                if (_endDate != null)
                  _buildFilterChip(
                    '종료일: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                    () {
                      setState(() {
                        _endDate = null;
                      });
                      _loadLogs();
                    },
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, size: 18),
            onPressed: () {
              setState(() {
                _selectedAdmin = null;
                _selectedAction = null;
                _startDate = null;
                _endDate = null;
              });
              _loadLogs();
            },
            tooltip: '필터 초기화',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      backgroundColor: Colors.blue.withOpacity(0.1),
      deleteIconColor: Colors.blue,
      labelStyle: const TextStyle(color: Colors.blue),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildMobileLogList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _managementController.activityLogs.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final log = _managementController.activityLogs[index];
        return _buildMobileLogItem(log);
      },
    );
  }

  Widget _buildMobileLogItem(AdminActivityLog log) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.adminName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildActionChip(log.action),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(log.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getTargetTypeIcon(log.targetType),
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_getTargetTypeDisplayName(log.targetType)}: ${log.targetId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text(
                '변경 내용',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              initiallyExpanded: false,
              children: [
                if (log.before.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    '변경 전:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatLogData(log.before),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (log.after.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    '변경 후:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatLogData(log.after),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLogList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '활동 로그',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('시간')),
                    DataColumn(label: Text('관리자')),
                    DataColumn(label: Text('작업')),
                    DataColumn(label: Text('대상')),
                    DataColumn(label: Text('세부 정보')),
                  ],
                  rows: _managementController.activityLogs.map((log) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatDateTime(log.timestamp))),
                        DataCell(
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAdmin = log.adminId;
                              });
                              _loadLogs();
                            },
                            child: Text(
                              log.adminName,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        DataCell(_buildActionChip(log.action)),
                        DataCell(Text(
                            '${_getTargetTypeDisplayName(log.targetType)}: ${log.targetId}')),
                        DataCell(
                          TextButton(
                            onPressed: () => _showLogDetailDialog(log),
                            child: const Text('상세보기'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(String action) {
    Color color;

    // 액션에 따른 색상 설정
    if (action.contains('create')) {
      color = Colors.green;
    } else if (action.contains('delete')) {
      color = Colors.red;
    } else if (action.contains('update') || action.contains('edit')) {
      color = Colors.orange;
    } else if (action.contains('login')) {
      color = Colors.blue;
    } else if (action.contains('logout')) {
      color = Colors.purple;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getActionDisplayName(action),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final List<String> adminNames = _managementController.activityLogs
        .map((log) => log.adminName)
        .toSet()
        .toList();

    final List<String> actions = _managementController.activityLogs
        .map((log) => log.action)
        .toSet()
        .toList();

    String? tempSelectedAdmin = _selectedAdmin;
    String? tempSelectedAction = _selectedAction;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    Get.dialog(
      AlertDialog(
        title: const Text('활동 로그 필터'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 관리자 선택
              const Text('관리자'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: tempSelectedAdmin,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('모든 관리자'),
                  ),
                  ...adminNames
                      .map((name) => DropdownMenuItem<String?>(
                            value: name,
                            child: Text(name),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  tempSelectedAdmin = value;
                },
              ),
              const SizedBox(height: 16),

              // 작업 선택
              const Text('작업'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: tempSelectedAction,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('모든 작업'),
                  ),
                  ...actions
                      .map((action) => DropdownMenuItem<String?>(
                            value: action,
                            child: Text(_getActionDisplayName(action)),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  tempSelectedAction = value;
                },
              ),
              const SizedBox(height: 16),

              // 기간 선택
              const Text('기간'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '시작일',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: tempStartDate != null
                            ? DateFormat('yyyy-MM-dd').format(tempStartDate!)
                            : '',
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          tempStartDate = picked;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '종료일',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: tempEndDate != null
                            ? DateFormat('yyyy-MM-dd').format(tempEndDate!)
                            : '',
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempEndDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          tempEndDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            23,
                            59,
                            59,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedAdmin = tempSelectedAdmin;
                _selectedAction = tempSelectedAction;
                _startDate = tempStartDate;
                _endDate = tempEndDate;
              });
              _loadLogs();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }

  void _showLogDetailDialog(AdminActivityLog log) {
    Get.dialog(
      AlertDialog(
        title: Text('활동 로그 상세 - ${_getActionDisplayName(log.action)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('관리자', log.adminName),
              _buildDetailItem('작업', _getActionDisplayName(log.action)),
              _buildDetailItem('시간', _formatDateTime(log.timestamp)),
              _buildDetailItem(
                  '대상 유형', _getTargetTypeDisplayName(log.targetType)),
              _buildDetailItem('대상 ID', log.targetId),
              const Divider(),
              if (log.before.isNotEmpty) ...[
                const Text(
                  '변경 전:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formatLogData(log.before)),
                ),
                const SizedBox(height: 16),
              ],
              if (log.after.isNotEmpty) ...[
                const Text(
                  '변경 후:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formatLogData(log.after)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  String _formatLogData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return '정보 없음';
    }

    final StringBuffer buffer = StringBuffer();
    data.forEach((key, value) {
      // timestamp 처리
      if (key == 'timestamp' && value is Timestamp) {
        value = DateFormat('yyyy-MM-dd HH:mm:ss').format(value.toDate());
      }

      buffer.write('$key: $value\n');
    });

    return buffer.toString().trim();
  }

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'login':
        return '로그인';
      case 'logout':
        return '로그아웃';
      case 'create_admin':
        return '관리자 생성';
      case 'update_admin':
        return '관리자 수정';
      case 'activate_admin':
        return '관리자 활성화';
      case 'deactivate_admin':
        return '관리자 비활성화';
      case 'reset_admin_password':
        return '비밀번호 재설정';
      case 'change_password':
        return '비밀번호 변경';
      case 'create_product':
        return '상품 생성';
      case 'update_product':
        return '상품 수정';
      case 'delete_product':
        return '상품 삭제';
      case 'update_inventory':
        return '재고 수정';
      case 'create_order':
        return '주문 생성';
      case 'update_order':
        return '주문 수정';
      case 'cancel_order':
        return '주문 취소';
      case 'refund_order':
        return '주문 환불';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  String _getTargetTypeDisplayName(String targetType) {
    switch (targetType) {
      case 'admin':
        return '관리자';
      case 'product':
        return '상품';
      case 'order':
        return '주문';
      case 'customer':
        return '고객';
      case 'promotion':
        return '프로모션';
      case 'content':
        return '콘텐츠';
      case 'setting':
        return '설정';
      default:
        return targetType;
    }
  }

  IconData _getTargetTypeIcon(String targetType) {
    switch (targetType) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'product':
        return Icons.inventory;
      case 'order':
        return Icons.shopping_cart;
      case 'customer':
        return Icons.people;
      case 'promotion':
        return Icons.local_offer;
      case 'content':
        return Icons.article;
      case 'setting':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }
}
