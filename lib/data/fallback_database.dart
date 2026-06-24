import '../models/user_profile.dart';

/// Chamomile Fallback Database — 6 entries (one per motherhood phase).
/// Each entry contains all 9 daily page fields, pre-written and phase-appropriate.
/// Triggered on API error or when running in fallback-only mode.

DailyPageContent getFallback(String? phase) {
  final key = phase ?? 'baby';
  return _fallbackDB[key] ?? _fallbackDB['baby']!;
}

final Map<String, DailyPageContent> _fallbackDB = {
  'expecting': const DailyPageContent(
    openingThought:
        'You are growing a universe inside you — and the universe is taking its time, as all sacred things do.',
    reflection:
        'What part of waiting feels the heaviest today — and what part feels the most wonder?',
    reflectionFollowup: 'Do you know what is behind this feeling?',
    emotionalFeeling:
        'You may be carrying a quiet mix of excitement and exhaustion — the kind that no one sees because you\'re still showing up.',
    emotionalNeed:
        'You need permission to slow down without guilt. To rest as an act of creation, not laziness.',
    emotionalResponse:
        'Everything you feel right now is part of the becoming. The worry, the hope, the strange grief for the life you had before — it all belongs here. You don\'t have to sort it. Just let it be.',
    insight:
        'Pregnancy is the only time in life where doing absolutely nothing is also doing everything.',
    microSkill:
        'Place both hands on your belly. Breathe in for four counts. Whisper one word that describes what you hope for. That\'s today\'s ritual.',
    gentleRead:
        'Your body is performing millions of precise biological events right now, without a single instruction from you. Your heart is pumping 50% more blood than usual. Your bones are softening to make room. You are not idle — you are extraordinary. Research shows that the mother\'s emotional state shapes the baby\'s nervous system. So every moment of peace you find is a gift to both of you.',
    funMoment:
        'If your baby could text you right now, what would they say? (Probably "stop eating spicy food at midnight.")',
    nightReflection:
        'What did your body do for you today that you didn\'t thank it for?',
  ),

  'newborn': const DailyPageContent(
    openingThought:
        'You are someone\'s entire world right now — and you don\'t have to be perfect to be everything.',
    reflection:
        'When was the last time you did something just for yourself — even for thirty seconds?',
    reflectionFollowup: 'Do you know what is behind this feeling?',
    emotionalFeeling:
        'You may be carrying an invisible weight — the love that is so fierce it frightens you, mixed with an exhaustion that has no bottom.',
    emotionalNeed:
        'You need someone to hold you the way you hold your baby — without conditions, without clocks.',
    emotionalResponse:
        'The early days are a blur of feeding and soothing and wondering if you\'re doing it right. You are. The fact that you worry about it is the proof. Not every moment has to feel beautiful for this to be a beautiful chapter.',
    insight:
        'No mother in history has felt ready. Every single one of them learned on the job — including the ones who looked like they had it together.',
    microSkill:
        'During the next feed, close your eyes for ten seconds and just listen to your baby breathing. That rhythm is your rhythm now. Let it slow you down.',
    gentleRead:
        'The newborn phase rewires your brain — literally. Neuroscience shows that new mothers develop heightened emotional sensitivity, sharper hearing, and faster threat detection. What feels like anxiety is often your brain upgrading itself for the most important job it will ever do. You\'re not falling apart. You\'re being rebuilt.',
    funMoment:
        'Name one thing your baby does that is objectively ridiculous but you find completely adorable.',
    nightReflection:
        'What is one thing you did today that your baby will never remember — but you will?',
  ),

  'baby': const DailyPageContent(
    openingThought:
        'Some days you lead, some days you follow — and some days you just survive. All three count.',
    reflection:
        'What part of you existed before motherhood that you\'d like to visit today, even just in your mind?',
    reflectionFollowup: 'Do you know what is behind this feeling?',
    emotionalFeeling:
        'You might be carrying the weight of being "on" all the time — the constant vigilance that no one else seems to notice.',
    emotionalNeed:
        'You need a pocket of silence. Not a solution, not a break — just five minutes where no one needs anything from you.',
    emotionalResponse:
        'You\'ve been holding so much. The meals, the naps, the developmental milestones you Google at 2am, the guilt when you check your phone, the guilt when you don\'t. None of that makes you less. It makes you human. And human is enough.',
    insight:
        'Your baby doesn\'t need a perfect mother. They need a present one. And "present" includes the days when you\'re barely holding on — because you\'re still there.',
    microSkill:
        'Put your hand on your chest. Feel your heartbeat. Count five beats. That\'s your body reminding you it\'s still taking care of you, even when you forget to.',
    gentleRead:
        'Between 6 and 18 months, babies develop what psychologists call "secure attachment" — and the single biggest predictor isn\'t perfection, it\'s repair. When you lose patience and come back with warmth, when you miss a cue and try again — that\'s what builds trust. The rupture-and-repair cycle is not failure. It\'s the mechanism of love.',
    funMoment:
        'What\'s the weirdest thing you\'ve found in your bag recently that definitely wasn\'t there before you had a baby?',
    nightReflection:
        'If you could bottle one feeling from today and keep it forever, which one would it be?',
  ),

  'toddler': const DailyPageContent(
    openingThought:
        'You are raising a tiny revolutionary who has opinions about socks — and somehow, you are the steady ground beneath all that glorious chaos.',
    reflection:
        'Where in your day do you lose yourself — and where, even briefly, do you find yourself again?',
    reflectionFollowup: 'Do you know what is behind this feeling?',
    emotionalFeeling:
        'You might be carrying the paradox of loving the person who exhausts you most — and feeling guilty about both the love and the exhaustion.',
    emotionalNeed:
        'You need someone to say: "You\'re doing an incredible job and it\'s okay that it doesn\'t feel like it."',
    emotionalResponse:
        'The toddler years test every version of patience you thought you had — and then they hand you a soggy cracker like it\'s a diamond and suddenly none of it matters. You are not failing on the hard days. You are weathering them. There\'s a difference.',
    insight:
        'A toddler\'s tantrum is not a reflection of your parenting. It\'s a reflection of a tiny brain doing the hardest developmental work of its life — and you\'re the safe place where that work happens.',
    microSkill:
        'Next time the noise feels like too much, press your fingertips together hard for five seconds, then release. Feel the tingle. That\'s your nervous system resetting. Takes three seconds.',
    gentleRead:
        'Toddlers say "no" an average of 25 times per hour — not because they\'re defiant, but because they\'re practicing autonomy for the first time. Every "no" is a tiny act of selfhood. It\'s exhausting to witness, but it\'s also proof that you\'ve raised a child who feels safe enough to disagree with you. That safety came from you.',
    funMoment:
        'What\'s the most absurd reason your toddler has cried this week? (Bonus points if it involved a banana.)',
    nightReflection:
        'What moment today — even a tiny one — made you think "I wouldn\'t trade this"?',
  ),

  'preschool': const DailyPageContent(
    openingThought:
        'They\'re starting to carry their own stories now — and you\'re learning that letting go is its own kind of holding on.',
    reflection:
        'What are you grieving about the stage that just ended — and what are you quietly excited about in the one beginning?',
    reflectionFollowup: 'Do you know what is behind this feeling?',
    emotionalFeeling:
        'You may be feeling the strange ache of being needed less — not because they love you less, but because you did your job so well they\'re ready to try the world.',
    emotionalNeed:
        'You need to remember that your identity is larger than motherhood — and that remembering this isn\'t selfish, it\'s necessary.',
    emotionalResponse:
        'This stage brings a bittersweet freedom. They go to school, they make friends you\'ve never met, they come home with jokes you didn\'t teach them. It\'s beautiful and it stings. Both of those are true, and neither cancels the other.',
    insight:
        'The preschool years are when children build their inner voice — and that voice will sound a lot like yours. Speak kindly to yourself. They\'re listening.',
    microSkill:
        'Write one sentence about who you were before you became a mother. Put it somewhere you\'ll see it tomorrow. Not to go back — just to remember she\'s still in there.',
    gentleRead:
        'Children between 3 and 5 are developing what psychologists call "theory of mind" — the ability to understand that other people have thoughts and feelings different from their own. When your child asks "Are you sad, Mummy?" they\'re performing one of the most complex cognitive tasks a human brain can do. They learned it from watching you. Your emotional honesty is their curriculum.',
    funMoment:
        'What\'s the most creative excuse your child has given for not going to bed? Academy Award performance or amateur hour?',
    nightReflection:
        'What did your child teach you today that they don\'t even know they taught you?',
  ),

  'school_age': const DailyPageContent(
    openingThought:
        'You have loved this person through every version of themselves — and the hardest part is realising they\'re becoming someone you\'ll have to get to know all over again.',
    reflection:
        'What conversation have you been avoiding — with your child, with yourself — that might change something if you had it?',
    reflectionFollowup: 'Do you know what is behind this feeling?',
    emotionalFeeling:
        'You may be carrying the quiet loneliness of a mother whose child is growing away — not because something is wrong, but because everything is going exactly right.',
    emotionalNeed:
        'You need to reconnect with the parts of you that motherhood put on hold — the friendships, the ambitions, the small pleasures that used to define your weekends.',
    emotionalResponse:
        'When they were small, you wished for this freedom. Now that it\'s here, it feels like loss. That\'s not ungrateful — that\'s the full spectrum of love. You gave them roots. Now you\'re watching the branches. Both are your work.',
    insight:
        'The school-age years are when your child stops asking you to play and starts watching how you live. Your joy is no longer optional — it\'s their blueprint.',
    microSkill:
        'Send a message to someone you haven\'t spoken to in months. Not about your kids. About you. One sentence is enough. Reconnection starts small.',
    gentleRead:
        'Research on school-age children shows that the single most protective factor against anxiety and behavioural issues is not academic achievement, extracurriculars, or screen-time limits — it\'s the quality of the parent-child relationship. And quality doesn\'t mean quantity. One genuinely connected conversation per day outperforms hours of supervised homework. You don\'t need to do more. You need to be present when you\'re there.',
    funMoment:
        'If your child wrote a performance review of you as a parent, what would be your highest-rated skill? And what would need "improvement"?',
    nightReflection:
        'When was the last time you laughed — really laughed — with your child? What was it about?',
  ),
};
