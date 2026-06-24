import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';

class CircleTab extends StatefulWidget {
  final AppTokens t;
  final String userName;
  const CircleTab({super.key, required this.t, required this.userName});

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  String _newPost = '';
  bool _isAnon = false;
  final List<_Post> _posts = [
    // Seeded posts for a non-empty feel
    _Post(
      name: 'A quiet mother',
      body: 'Today I realised that I haven\'t listened to my favourite song in months. I played it during nap time and cried. Not from sadness — from recognition. I\'m still in here.',
      isAnon: true,
      time: '2 hours ago',
      hearts: 14,
      hugs: 8,
      leaves: 3,
    ),
    _Post(
      name: 'Priya',
      body: 'My toddler held my face with both hands today and said "Mama, you\'re my best." I didn\'t correct his grammar. I just held that moment.',
      isAnon: false,
      time: '5 hours ago',
      hearts: 22,
      hugs: 11,
      leaves: 7,
    ),
    _Post(
      name: 'A quiet mother',
      body: 'Some days the hardest thing isn\'t the baby. It\'s the loneliness that sits next to you while you\'re surrounded by people who love you.',
      isAnon: true,
      time: 'Yesterday',
      hearts: 31,
      hugs: 19,
      leaves: 5,
    ),
  ];

  AppTokens get t => widget.t;

  void _sharePost() {
    if (_newPost.trim().isEmpty) return;
    setState(() {
      _posts.insert(
        0,
        _Post(
          name: _isAnon ? 'A quiet mother' : widget.userName,
          body: _newPost.trim(),
          isAnon: _isAnon,
          time: 'Just now',
          hearts: 0,
          hugs: 0,
          leaves: 0,
        ),
      );
      _newPost = '';
      _isAnon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        children: [
          // Post composer
          _buildComposer(),
          const SizedBox(height: 16),
          // Posts
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
              // Anonymous checkbox
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
                        color: _isAnon
                            ? t.accent
                            : Colors.transparent,
                      ),
                      child: _isAnon
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
              // Share button
              GestureDetector(
                onTap: hasText ? _sharePost : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
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

  Widget _buildPostCard(_Post post) {
    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                post.isAnon ? 'A quiet mother' : post.name,
                style: AppTypography.lato700(12, t.accent),
              ),
              Text(
                post.time,
                style: AppTypography.lato400(11, t.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Body
          Text(
            post.body,
            style: AppTypography.cormorantItalic(17, t.text, height: 1.7),
          ),
          const SizedBox(height: 14),
          // Reactions
          Row(
            children: [
              _reactionBtn(
                AppIcons.heart(c: t.accent, s: 16),
                post.hearts,
                t.accent,
                () => setState(() => post.hearts++),
              ),
              const SizedBox(width: 10),
              _reactionBtn(
                AppIcons.hug(c: t.green, s: 16),
                post.hugs,
                t.green,
                () => setState(() => post.hugs++),
              ),
              const SizedBox(width: 10),
              _reactionBtn(
                AppIcons.leaf(c: t.gold, s: 16),
                post.leaves,
                t.gold,
                () => setState(() => post.leaves++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reactionBtn(
      Widget icon, int count, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              '$count',
              style: AppTypography.lato400(12, color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Post {
  final String name;
  final String body;
  final bool isAnon;
  final String time;
  int hearts;
  int hugs;
  int leaves;

  _Post({
    required this.name,
    required this.body,
    required this.isAnon,
    required this.time,
    required this.hearts,
    required this.hugs,
    required this.leaves,
  });
}
