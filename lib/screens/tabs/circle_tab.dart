import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';

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

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() async {
    setState(() => _loadingPosts = true);

    try {
      final postsList = await ApiService.getCirclePosts(
        token: widget.user.token ?? '',
      );

      final loadedPosts = postsList.map((item) {
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
            timeString = diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
          } else if (diff.inHours > 0) {
            timeString = diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
          } else if (diff.inMinutes > 0) {
            timeString = diff.inMinutes == 1 ? '1 minute ago' : '${diff.inMinutes} minutes ago';
          }
        } catch (_) {}

        final myReactions = (item['my_reactions'] as List<dynamic>? ?? [])
            .map((r) => r.toString())
            .toSet();

        return _Post(
          id: id,
          name: isAnon ? 'A quiet mother' : author,
          body: body,
          isAnon: isAnon,
          time: timeString,
          hearts: item['heart_count'] as int? ?? 0,
          hugs: item['hug_count'] as int? ?? 0,
          leaves: item['leaf_count'] as int? ?? 0,
          myReactions: myReactions,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _posts
            ..clear()
            ..addAll(loadedPosts);
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
        isAnon: anon,
      );
      final createdId = res['id']?.toString();

      if (mounted) {
        setState(() {
          _posts.insert(
            0,
            _Post(
              id: createdId,
              name: anon ? 'A quiet mother' : widget.userName,
              body: bodyText,
              isAnon: anon,
              time: 'Just now',
              hearts: 0,
              hugs: 0,
              leaves: 0,
              myReactions: {},
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('[CREATE CIRCLE POST ERROR] $e');
      if (mounted) {
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
  }

  Future<void> _toggleReaction(_Post post, String type) async {
    if (post.id == null) return;

    // Optimistic update
    final hadReaction = post.myReactions.contains(type);
    setState(() {
      if (hadReaction) {
        post.myReactions.remove(type);
        if (type == 'heart') post.hearts = (post.hearts - 1).clamp(0, 999999);
        if (type == 'hug')   post.hugs   = (post.hugs   - 1).clamp(0, 999999);
        if (type == 'leaf')  post.leaves  = (post.leaves  - 1).clamp(0, 999999);
      } else {
        post.myReactions.add(type);
        if (type == 'heart') post.hearts++;
        if (type == 'hug')   post.hugs++;
        if (type == 'leaf')  post.leaves++;
      }
    });

    try {
      final updated = await ApiService.reactToCirclePost(
        token: widget.user.token ?? '',
        postId: post.id!,
        reactionType: type,
      );
      // Sync with authoritative server counts
      if (mounted && updated != null) {
        setState(() {
          post.hearts = updated['heart_count'] as int? ?? post.hearts;
          post.hugs   = updated['hug_count']   as int? ?? post.hugs;
          post.leaves = updated['leaf_count']  as int? ?? post.leaves;
          post.myReactions = (updated['my_reactions'] as List<dynamic>? ?? [])
              .map((r) => r.toString())
              .toSet();
        });
      }
    } catch (err) {
      debugPrint('[REACT $type ERROR] $err');
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          if (hadReaction) {
            post.myReactions.add(type);
            if (type == 'heart') post.hearts++;
            if (type == 'hug')   post.hugs++;
            if (type == 'leaf')  post.leaves++;
          } else {
            post.myReactions.remove(type);
            if (type == 'heart') post.hearts = (post.hearts - 1).clamp(0, 999999);
            if (type == 'hug')   post.hugs   = (post.hugs   - 1).clamp(0, 999999);
            if (type == 'leaf')  post.leaves  = (post.leaves  - 1).clamp(0, 999999);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        children: [
          _buildComposer(),
          const SizedBox(height: 16),
          if (_loadingPosts)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            ..._posts.map((post) => _buildPostCard(post)),
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
                      child: _isAnon ? AppIcons.check(c: Colors.white, s: 12) : null,
                    ),
                    const SizedBox(width: 8),
                    Text('Post anonymously', style: AppTypography.lato400(12, t.muted)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: hasText ? _sharePost : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: hasText ? t.accent : t.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      AppIcons.share(c: hasText ? Colors.white : t.muted, s: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: AppTypography.lato700(12, hasText ? Colors.white : t.muted),
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

  Widget _buildPostCard(_Post post) {
    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                post.isAnon ? 'A quiet mother' : post.name,
                style: AppTypography.lato700(12, t.accent),
              ),
              Text(post.time, style: AppTypography.lato400(11, t.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.body,
            style: AppTypography.cormorantItalic(17, t.text, height: 1.7),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _reactionBtn(
                icon: AppIcons.heart(
                  c: t.accent,
                  s: 16,
                  filled: post.myReactions.contains('heart'),
                ),
                count: post.hearts,
                color: t.accent,
                active: post.myReactions.contains('heart'),
                onTap: () => _toggleReaction(post, 'heart'),
              ),
              const SizedBox(width: 10),
              _reactionBtn(
                icon: AppIcons.hug(
                  c: t.green,
                  s: 16,
                  filled: post.myReactions.contains('hug'),
                ),
                count: post.hugs,
                color: t.green,
                active: post.myReactions.contains('hug'),
                onTap: () => _toggleReaction(post, 'hug'),
              ),
              const SizedBox(width: 10),
              _reactionBtn(
                icon: AppIcons.leaf(
                  c: t.gold,
                  s: 16,
                  filled: post.myReactions.contains('leaf'),
                ),
                count: post.leaves,
                color: t.gold,
                active: post.myReactions.contains('leaf'),
                onTap: () => _toggleReaction(post, 'leaf'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reactionBtn({
    required Widget icon,
    required int count,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : t.border),
          color: active ? color.withAlpha(20) : Colors.transparent,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Text('$count', style: AppTypography.lato400(12, color)),
          ],
        ),
      ),
    );
  }
}

class _Post {
  final String? id;
  final String name;
  final String body;
  final bool isAnon;
  final String time;
  int hearts;
  int hugs;
  int leaves;
  Set<String> myReactions;

  _Post({
    this.id,
    required this.name,
    required this.body,
    required this.isAnon,
    required this.time,
    required this.hearts,
    required this.hugs,
    required this.leaves,
    required this.myReactions,
  });
}
