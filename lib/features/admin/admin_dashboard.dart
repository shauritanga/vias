import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/content_management_service.dart';
import '../../core/services/user_management_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/tts_service.dart';
import '../../shared/widgets/pdf_upload_widget.dart';

/// Admin dashboard for managing DIT prospectus content
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late ContentManagementService _contentService;
  late UserManagementService _userService;
  late AnalyticsService _analyticsService;
  late TTSService _ttsService;
  late TabController _tabController;

  String _statusMessage = 'Admin Dashboard Ready';

  @override
  void initState() {
    super.initState();
    _contentService = ContentManagementService();
    _userService = UserManagementService();
    _analyticsService = AnalyticsService();
    _ttsService = context.read<TTSService>();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize sample data
    _userService.initializeSampleData();
    _analyticsService.initializeSampleData();

    // Welcome message for admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _speakWelcomeMessage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _ttsService.speak(
      'Welcome to the VIAS Admin Dashboard. '
      'Here you can upload prospectus documents, manage content, '
      'monitor system usage, and manage users. '
      'Use the navigation tabs to access different sections.',
    );
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VIAS Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.upload_file), text: 'Content'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  DateTime.now().toString().substring(0, 16),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildContentTab(),
                _buildAnalyticsTab(),
                _buildUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Quick Stats Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Programs',
                  '${_contentService.programs.length}',
                  Icons.school,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Fee Structures',
                  '${_contentService.feeStructures.length}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildStatCard(
                  'Admission Info',
                  '${_contentService.admissionInfo.length}',
                  Icons.info,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Content Items',
                  '${_contentService.generalContent.length}',
                  Icons.description,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // PDF Upload Section
          PDFUploadWidget(
            onProcessingComplete: (result) {
              if (result.success) {
                String message;
                String speechMessage;

                if (result.aiProcessed) {
                  message =
                      'PDF processed successfully with AI integration! '
                      '${result.totalChunks ?? 0} content chunks created with OpenAI embeddings. '
                      'Content is now available for intelligent Q&A.';
                  speechMessage =
                      'PDF prospectus has been processed with AI integration. '
                      '${result.totalChunks ?? 0} content chunks created. '
                      'Intelligent question and answer system is now ready.';
                } else {
                  message =
                      'PDF processed successfully! Content saved to Firebase database and is now available.';
                  speechMessage =
                      'PDF prospectus has been processed and saved to Firebase database. Content is now available to users.';
                }

                _updateStatus(message);
                _ttsService.speak(speechMessage);
                setState(() {}); // Refresh the stats
              } else {
                _updateStatus('PDF processing failed: ${result.message}');
                _ttsService.speak('Failed to process PDF: ${result.message}');
              }
            },
          ),

          const SizedBox(height: 16),

          // Content Summary
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Content Summary',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildContentSummary()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final usageStats = _analyticsService.getUsageStatistics();
    final performanceStats = _analyticsService.getPerformanceStatistics();
    final engagementStats = _analyticsService.getUserEngagementStatistics();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Analytics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Real-time Stats Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Events',
                  '${usageStats['total_events']}',
                  Icons.analytics,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Voice Commands',
                  '${usageStats['voice_commands']}',
                  Icons.mic,
                  Colors.green,
                ),
                _buildStatCard(
                  'Active Users',
                  '${engagementStats['active_users']}',
                  Icons.people,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Avg Response Time',
                  '${performanceStats['average_response_time']?.toStringAsFixed(1) ?? '0.0'}s',
                  Icons.speed,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Success Rate',
                  '${usageStats['success_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.check_circle,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Session Duration',
                  '${engagementStats['average_session_duration']?.toStringAsFixed(1) ?? '0.0'}m',
                  Icons.timer,
                  Colors.indigo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final activeUsers = _userService.getActiveUsers();
    final supportRequests = _userService.supportRequests;
    final openRequests = supportRequests
        .where((req) => req.status == SupportStatus.open)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // User Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '${_userService.users.length}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Users',
                  '${activeUsers.length}',
                  Icons.people_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Open Requests',
                  '$openRequests',
                  Icons.support_agent,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User List
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Users',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: activeUsers.length,
                        itemBuilder: (context, index) {
                          final user = activeUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.role == UserRole.admin
                                  ? Colors.red
                                  : Colors.blue,
                              child: Icon(
                                user.role == UserRole.admin
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  user.role.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: user.role == UserRole.admin
                                        ? Colors.red
                                        : Colors.blue,
                                  ),
                                ),
                                Text(
                                  'Last active: ${_formatLastActive(user.lastActive)}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSummary() {
    if (_contentService.programs.isEmpty &&
        _contentService.feeStructures.isEmpty &&
        _contentService.admissionInfo.isEmpty &&
        _contentService.generalContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No content uploaded yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a PDF prospectus to get started',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (_contentService.programs.isNotEmpty) ...[
          _buildContentSection(
            'Programs',
            _contentService.programs.length,
            Icons.school,
          ),
          ..._contentService.programs
              .take(3)
              .map(
                (program) =>
                    _buildContentItem(program.name, program.description),
              ),
        ],
        if (_contentService.feeStructures.isNotEmpty) ...[
          _buildContentSection(
            'Fee Structures',
            _contentService.feeStructures.length,
            Icons.attach_money,
          ),
          ..._contentService.feeStructures
              .take(3)
              .map(
                (fee) => _buildContentItem(
                  fee.programName,
                  'Total: ${fee.totalFee.toStringAsFixed(0)} ${fee.currency}',
                ),
              ),
        ],
        if (_contentService.admissionInfo.isNotEmpty) ...[
          _buildContentSection(
            'Admission Information',
            _contentService.admissionInfo.length,
            Icons.info,
          ),
          ..._contentService.admissionInfo
              .take(3)
              .map(
                (admission) =>
                    _buildContentItem(admission.title, admission.description),
              ),
        ],
      ],
    );
  }

  Widget _buildContentSection(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildContentItem(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      dense: true,
    );
  }
}
