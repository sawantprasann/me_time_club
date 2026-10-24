import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../models/circle_response.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';
import '../../widgets/circle_post_card.dart';

class CircleTab extends StatefulWidget {
  final UserProfile user;
  final AppTokens t;
  final String userName;
  const CircleTab({
    super.key,
    required this.user,
    required this.t,
    required this.userName,
  });

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  String _newPost = '';
  bool _isAnon = false;
  bool _loadingPosts = false;
  final List<_Post> _posts = [];
  final List<CircleMood> _moods = [];

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _loadingPosts = true);
    }

    try {
      final token = widget.user.token ?? '';
      final results = await Future.wait([
        ApiService.getCirclePosts(token: token),
        ApiService.getCircleMoods(token: token),
      ]);

      final postsList = results[0];
      final moodsList = results[1] as List<CircleMood>;

      final loadedPosts =
          postsList.map((item) {
            final id = item['id']?.toString();
            final body = item['body']?.toString() ?? '';
            final isAnon = item['anonymous'] as bool? ?? true;
            final author = item['author']?.toString() ?? 'A quiet mother';
            final createdAtStr = item['created_at']?.toString() ?? '';

            String timeString = 'Just now';
            try {
              final createdAt = DateTime.parse(createdAtStr);
              final diff = DateTime.now().difference(createdAt);
              if (diff.inDays > 0) {
                timeString = '${diff.inDays}d ago';
              } else if (diff.inHours > 0) {
                timeString = '${diff.inHours}h ago';
              } else if (diff.inMinutes > 0) {
                timeString = '${diff.inMinutes}m ago';
              }
            } catch (_) {}

            return _Post(
              id: id,
              name: isAnon ? 'Anonymous' : author,
              body: body,
              isAnon: isAnon,
              time: timeString,
              myMood: item['my_mood'] as String?,
              replies:
                  (item['responses'] as List<dynamic>? ?? [])
                      .whereType<Map<String, dynamic>>()
                      .map(CircleReply.fromJson)
                      .where((reply) => reply.body.trim().isNotEmpty)
                      .toList(),
            );
          }).toList();

      if (mounted) {
        setState(() {
          _posts
            ..clear()
            ..addAll(loadedPosts);
          _moods
            ..clear()
            ..addAll(moodsList);
          _loadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('[LOAD CIRCLE POSTS ERROR] $e');
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  void _sharePost() async {
    if (_newPost.trim().isEmpty) return;
    final bodyText = _newPost.trim();
    final anon = _isAnon;
    setState(() {
      _newPost = '';
      _isAnon = false;
    });

    try {
      final res = await ApiService.createCirclePost(
        token: widget.user.token ?? '',
        body: bodyText,
        anonymous: anon,
      );
      final createdId = res['id']?.toString();
      final isAnonymous = res['anonymous'] as bool? ?? anon;
      final authorName = res['author']?.toString() ?? (isAnonymous ? 'Anonymous' : widget.userName);

      if (mounted) {
        setState(() {
          _posts.insert(
            0,
            _Post(
              id: createdId,
              name: isAnonymous ? 'Anonymous' : authorName,
              body: bodyText,
              isAnon: isAnonymous,
              time: 'Just now',
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('[CREATE CIRCLE POST ERROR] $e');
      if (e is UnauthorizedException || !mounted) return;
      setState(() {
        _newPost = bodyText;
        _isAnon = anon;
      });
      String errMsg = e.toString();
      if (errMsg.startsWith('Exception: ')) errMsg = errMsg.substring(11);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: t.accent,
      backgroundColor: t.card,
      onRefresh: () => _loadPosts(showSpinner: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          children: [
            _buildComposer(),
            const SizedBox(height: 16),
            if (_loadingPosts && _posts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                    ),
                  ),
                ),
              )
            else
              ..._posts.map((post) => _buildPostCard(post)),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final hasText = _newPost.trim().isNotEmpty;
    return AppCard(
      t: t,
      child: Column(
        children: [
          VoiceTextArea(
            value: _newPost,
            onChange: (v) => setState(() => _newPost = v),
            placeholder: 'Share a thought, a feeling, a moment…',
            t: t,
            rows: 3,
            micSize: 34,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isAnon = !_isAnon),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isAnon ? t.accent : t.border,
                          width: 1.5,
                        ),
                        color: _isAnon ? t.accent : Colors.transparent,
                      ),
                      child:
                          _isAnon
                              ? AppIcons.check(c: Colors.white, s: 12)
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Post anonymously',
                      style: AppTypography.lato400(12, t.muted),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: hasText ? _sharePost : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: hasText ? t.accent : t.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      AppIcons.share(
                        c: hasText ? Colors.white : t.muted,
                        s: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: AppTypography.lato700(
                          12,
                          hasText ? Colors.white : t.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(_Post post) => CirclePostCard(
    key: ObjectKey(post),
    t: t,
    author: post.isAnon ? 'Anonymous' : post.name,
    body: post.body,
    time: post.time,
    replies: post.replies,
    moods: _moods,
    myMood: post.myMood,
    onSendReply: (draft) async {
      if (post.id == null) return;
      final updatedPost = await ApiService.respondToCirclePost(
        token: widget.user.token ?? '',
        postId: post.id!,
        moodKey: draft.feelingKey,
        body: draft.feelingKey == null ? draft.body : null,
        anonymous: true,
      );
      if (mounted) {
        setState(() {
          post.myMood = updatedPost['my_mood'] as String?;
          final rawResponses =
              updatedPost['responses'] as List<dynamic>? ?? [];
          post.replies
            ..clear()
            ..addAll(
              rawResponses
                  .whereType<Map<String, dynamic>>()
                  .map(CircleReply.fromJson)
                  .where((reply) => reply.body.trim().isNotEmpty),
            );
        });
      }
    },
  );
}

class _Post {
  final String? id;
  final String name;
  final String body;
  final bool isAnon;
  final String time;
  String? myMood;
  final List<CircleReply> replies;

  _Post({
    this.id,
    required this.name,
    required this.body,
    required this.isAnon,
    required this.time,
    this.myMood,
    this.replies = const [],
  });
}
