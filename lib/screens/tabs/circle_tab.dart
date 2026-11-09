import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final bool isActive;
  final int refreshTrigger;
  const CircleTab({
    super.key,
    required this.user,
    required this.t,
    required this.userName,
    this.isActive = true,
    this.refreshTrigger = 0,
  });

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  static const _mamaAuthor = 'a mama';

  String _newPost = '';
  bool _showName = false;
  bool _loadingPosts = false;
  final List<_Post> _posts = [];
  final List<CircleMood> _moods = [];

  AppTokens get t => widget.t;

  String get _presenceKey =>
      'circle_show_name_${widget.user.id ?? widget.userName}';

  @override
  void initState() {
    super.initState();
    _loadPresence();
    _loadPosts();
  }

  Future<void> _loadPresence() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_presenceKey);
    if (!mounted || saved == null) return;
    setState(() => _showName = saved);
  }

  Future<void> _togglePresence() async {
    final next = !_showName;
    setState(() => _showName = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_presenceKey, next);
  }

  String _authorLabel({
    required bool anonymous,
    String? author,
    String? namedFallback,
  }) {
    if (anonymous) return _mamaAuthor;
    final name = author?.trim() ?? '';
    if (name.isEmpty || name == 'Anonymous') {
      final fallback = namedFallback?.trim() ?? '';
      return fallback.isEmpty ? 'A quiet mother' : fallback;
    }
    return name;
  }

  @override
  void didUpdateWidget(CircleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isActive && !oldWidget.isActive) ||
        widget.refreshTrigger != oldWidget.refreshTrigger) {
      _loadPosts(showSpinner: false);
    }
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

            final payload = item is Map
                ? CirclePostPayload.fromJson(Map<String, dynamic>.from(item))
                : const CirclePostPayload(
                    comments: [],
                    feelings: [],
                    myMoods: [],
                    mamaCount: 0,
                  );

            return _Post(
              id: id,
              name: _authorLabel(anonymous: isAnon, author: author),
              body: body,
              isAnon: isAnon,
              mine: item['mine'] == true,
              time: timeString,
              myMood: item['my_mood'] as String?,
              myMoods: payload.myMoods,
              feelings: payload.feelings,
              mamaCount: payload.mamaCount,
              replies: payload.comments,
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
    final showName = _showName;
    setState(() => _newPost = '');

    try {
      final res = await ApiService.createCirclePost(
        token: widget.user.token ?? '',
        body: bodyText,
        anonymous: !showName,
      );
      final createdId = res['id']?.toString();
      final isAnonymous = res['anonymous'] as bool? ?? !showName;
      final authorName = res['author']?.toString();

      if (mounted) {
        setState(() {
          _posts.insert(
            0,
            _Post(
              id: createdId,
              name: _authorLabel(
                anonymous: isAnonymous,
                author: authorName,
                namedFallback: widget.userName,
              ),
              body: bodyText,
              isAnon: isAnonymous,
              mine: true,
              time: 'Just now',
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('[CREATE CIRCLE POST ERROR] $e');
      if (e is UnauthorizedException || !mounted) return;
      setState(() => _newPost = bodyText);
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
            _buildPresence(),
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

  Widget _buildPresence() {
    final color = _showName ? t.green : t.accent;
    final label = _showName ? 'as ${widget.userName}' : 'quietly';
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 10),
      child: Row(
        children: [
          Text("You're here", style: AppTypography.lato400(13, t.muted)),
          const Spacer(),
          GestureDetector(
            onTap: _togglePresence,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.lato600(12, color),
                    ),
                  ),
                  Text(
                    ' · tap to change',
                    style: AppTypography.lato400(12, t.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Future<void> _deletePost(_Post post) async {
    final id = post.id;
    if (id == null) return;
    final index = _posts.indexOf(post);
    setState(() => _posts.remove(post));
    try {
      await ApiService.deleteCirclePost(
        token: widget.user.token ?? '',
        postId: id,
      );
    } catch (e) {
      debugPrint('[DELETE CIRCLE POST ERROR] $e');
      if (!mounted) return;
      setState(() {
        final at = index.clamp(0, _posts.length);
        _posts.insert(at, post);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That post could not be removed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteComment(_Post post, CircleReply reply) async {
    final postId = post.id;
    final commentId = reply.id;
    if (postId == null || commentId == null) return;
    final previous = List<CircleReply>.from(post.replies);
    setState(() => post.replies.remove(reply));
    try {
      await ApiService.deleteCircleComment(
        token: widget.user.token ?? '',
        postId: postId,
        commentId: commentId,
      );
    } catch (e) {
      debugPrint('[DELETE CIRCLE COMMENT ERROR] $e');
      if (!mounted) return;
      setState(() {
        post.replies
          ..clear()
          ..addAll(previous);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That comment could not be removed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildPostCard(_Post post) => CirclePostCard(
    key: ObjectKey(post),
    t: t,
    author: post.name,
    body: post.body,
    time: post.time,
    mine: post.mine,
    onDeletePost: post.mine && post.id != null ? () => _deletePost(post) : null,
    onDeleteComment: (reply) => _deleteComment(post, reply),
    replies: post.replies,
    moods: _moods,
    myMood: post.myMood,
    myMoods: post.myMoods,
    feelings: post.feelings,
    mamaCount: post.mamaCount,
    onSendReply: (draft) async {
      if (post.id == null) return null;
      final updatedPost = await ApiService.respondToCirclePost(
        token: widget.user.token ?? '',
        postId: post.id!,
        moodKey: draft.feelingKey,
        body: draft.feelingKey == null ? draft.body : null,
        anonymous: !_showName,
      );
      final payload = CirclePostPayload.fromJson(updatedPost);

      if (mounted) {
        setState(() {
          post.myMood = updatedPost['my_mood'] as String?;
          post.myMoods
            ..clear()
            ..addAll(payload.myMoods);
          post.feelings
            ..clear()
            ..addAll(payload.feelings);
          post.mamaCount = payload.mamaCount;
          post.replies
            ..clear()
            ..addAll(payload.comments);
        });
      }
      return payload.comments;
    },
  );
}

class _Post {
  final String? id;
  final String name;
  final String body;
  final bool isAnon;
  final bool mine;
  final String time;
  String? myMood;
  final List<String> myMoods;
  final List<CircleFeelingCount> feelings;
  int mamaCount;
  final List<CircleReply> replies;

  _Post({
    this.id,
    required this.name,
    required this.body,
    required this.isAnon,
    this.mine = false,
    required this.time,
    this.myMood,
    List<String>? myMoods,
    List<CircleFeelingCount>? feelings,
    this.mamaCount = 0,
    List<CircleReply>? replies,
  }) : myMoods = myMoods ?? [],
       feelings = feelings ?? [],
       replies = replies ?? [];
}
