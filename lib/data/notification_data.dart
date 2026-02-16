import 'models/dhikr.dart';
import 'models/hadith.dart';
import 'package:flutter/material.dart';

/// Central repository for all static content used in both
/// screens and notifications.
class NotificationData {
  
  // ── Dhikr Data ─────────────────────────────────────────────────────────────
  
  static const List<DhikrCategory> dhikrCategories = [
    DhikrCategory(id: 'morning', nameArabic: 'أذكار الصباح', nameEnglish: 'Morning', icon: '🌅'),
    DhikrCategory(id: 'evening', nameArabic: 'أذكار المساء', nameEnglish: 'Evening', icon: '🌙'),
    DhikrCategory(id: 'afterPrayer', nameArabic: 'أذكار بعد الصلاة', nameEnglish: 'After Prayer', icon: '🕌'),
    DhikrCategory(id: 'sleep', nameArabic: 'أذكار النوم', nameEnglish: 'Sleep', icon: '😴'),
    DhikrCategory(id: 'general', nameArabic: 'أذكار عامة', nameEnglish: 'General', icon: '📿'),
  ];

  static const List<Dhikr> allDhikr = [
    // ── Morning Adhkar ──────────────────────────────────────
    Dhikr(id: 1, category: 'morning', textArabic: 'أصبحنا وأصبح الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير', textEnglish: 'We have entered the morning and the dominion belongs to Allah. All praise is for Allah. There is no deity except Allah alone, with no partner.', targetCount: 1),
    Dhikr(id: 2, category: 'morning', textArabic: 'اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور', textEnglish: 'O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the resurrection.', targetCount: 1),
    Dhikr(id: 3, category: 'morning', textArabic: 'سبحان الله وبحمده', textEnglish: 'Glory be to Allah and praise Him.', targetCount: 100),
    Dhikr(id: 4, category: 'morning', textArabic: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير', textEnglish: 'There is no deity except Allah alone, with no partner. His is the dominion and His is the praise, and He is over all things competent.', targetCount: 10),
    Dhikr(id: 5, category: 'morning', textArabic: 'اللهم إني أسألك العافية في الدنيا والآخرة، اللهم إني أسألك العفو والعافية في ديني ودنياي وأهلي ومالي', textEnglish: 'O Allah, I ask You for well-being in this world and the next. O Allah, I ask You for forgiveness and well-being in my religion, my worldly life, my family, and my wealth.', targetCount: 1),
    Dhikr(id: 6, category: 'morning', textArabic: 'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم', textEnglish: 'In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.', targetCount: 3),
    Dhikr(id: 7, category: 'morning', textArabic: 'اللهم عافني في بدني، اللهم عافني في سمعي، اللهم عافني في بصري، لا إله إلا أنت', textEnglish: 'O Allah, grant me health in my body. O Allah, grant me health in my hearing. O Allah, grant me health in my sight. There is no deity but You.', targetCount: 3),
    Dhikr(id: 8, category: 'morning', textArabic: 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم', textEnglish: 'Allah is sufficient for me. There is no deity except Him. I have placed my trust in Him, and He is the Lord of the Great Throne.', targetCount: 7),
    Dhikr(id: 36, category: 'morning', textArabic: 'اللهم أنت ربي لا إله إلا أنت، خلقتني وأنا عبدك، وأنا على عهدك ووعدك ما استطعت، أعوذ بك من شر ما صنعت، أبوء لك بنعمتك علي، وأبوء بذنبي فاغفر لي فإنه لا يغفر الذنوب إلا أنت', textEnglish: 'O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil that I have committed. I acknowledge Your grace upon me and I acknowledge my sin, so forgive me, for no one forgives sins but You.', reference: 'Sayyid al-Istighfar', targetCount: 1),
    Dhikr(id: 37, category: 'morning', textArabic: 'يا حي يا قيوم برحمتك أستغيث أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين', textEnglish: 'O Ever-Living, O Sustainer, by Your mercy I seek help. Rectify all my affairs and do not leave me to myself even for the blink of an eye.', targetCount: 1),
    Dhikr(id: 38, category: 'morning', textArabic: 'رضيت بالله ربا، وبالإسلام دينا، وبمحمد صلى الله عليه وسلم نبيا', textEnglish: 'I am content with Allah as my Lord, with Islam as my religion, and with Muhammad (peace and blessings of Allah be upon him) as my Prophet.', targetCount: 3),
    Dhikr(id: 39, category: 'morning', textArabic: 'أصبحنا على فطرة الإسلام وعلى كلمة الإخلاص، وعلى دين نبينا محمد صلى الله عليه وسلم، وعلى ملة أبينا إبراهيم، حنيفا مسلما وما كان من المشركين', textEnglish: 'We have entered the morning upon the natural religion of Islam, the word of sincere devotion, the religion of our Prophet Muhammad (peace and blessings of Allah be upon him), and the faith of our father Ibrahim, upright and submitting, and he was not of the polytheists.', targetCount: 1),

    // ── Evening Adhkar ──────────────────────────────────────
    Dhikr(id: 9, category: 'evening', textArabic: 'أمسينا وأمسى الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير', textEnglish: 'We have entered the evening and the dominion belongs to Allah. All praise is for Allah. There is no deity except Allah alone, with no partner.', targetCount: 1),
    Dhikr(id: 10, category: 'evening', textArabic: 'اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير', textEnglish: 'O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the final return.', targetCount: 1),
    Dhikr(id: 11, category: 'evening', textArabic: 'أعوذ بكلمات الله التامات من شر ما خلق', textEnglish: 'I seek refuge in the perfect words of Allah from the evil of what He has created.', targetCount: 3),
    Dhikr(id: 12, category: 'evening', textArabic: 'اللهم إني أعوذ بك من الهم والحزن، وأعوذ بك من العجز والكسل، وأعوذ بك من الجبن والبخل، وأعوذ بك من غلبة الدين وقهر الرجال', textEnglish: 'O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from cowardice and miserliness, and from being overcome by debt and the tyranny of men.', targetCount: 1),
    Dhikr(id: 13, category: 'evening', textArabic: 'اللهم إني أسألك العافية في الدنيا والآخرة', textEnglish: 'O Allah, I ask You for well-being in this world and the Hereafter.', targetCount: 1),
    Dhikr(id: 14, category: 'evening', textArabic: 'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم', textEnglish: 'In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.', targetCount: 3),
    Dhikr(id: 15, category: 'evening', textArabic: 'أعوذ بكلمات الله التامة من غضبه وعقابه وشر عباده ومن همزات الشياطين وأن يحضرون', textEnglish: 'I seek refuge in the perfect words of Allah from His anger, His punishment, and the evil of His servants, and from the whisperings of the devils and their presence.', targetCount: 1),
    Dhikr(id: 16, category: 'evening', textArabic: 'سبحان الله وبحمده', textEnglish: 'Glory be to Allah and praise Him.', targetCount: 100),
    Dhikr(id: 40, category: 'evening', textArabic: 'اللهم أنت ربي لا إله إلا أنت، خلقتني وأنا عبدك، وأنا على عهدك ووعدك ما استطعت، أعوذ بك من شر ما صنعت، أبوء لك بنعمتك علي، وأبوء بذنبي فاغفر لي فإنه لا يغفر الذنوب إلا أنت', textEnglish: 'O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil that I have committed. I acknowledge Your grace upon me and I acknowledge my sin, so forgive me, for no one forgives sins but You.', reference: 'Sayyid al-Istighfar', targetCount: 1),
    Dhikr(id: 41, category: 'evening', textArabic: 'اللهم ما أمسى بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك، فلك الحمد ولك الشكر', textEnglish: 'O Allah, whatever blessing has befallen me or any of Your creation during the evening is from You alone, without partner. To You is all praise and to You is all thanks.', targetCount: 1),
    Dhikr(id: 42, category: 'evening', textArabic: 'يا حي يا قيوم برحمتك أستغيث أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين', textEnglish: 'O Ever-Living, O Sustainer, by Your mercy I seek help. Rectify all my affairs and do not leave me to myself even for the blink of an eye.', targetCount: 1),

    // ── After Prayer Adhkar ─────────────────────────────────
    Dhikr(id: 17, category: 'afterPrayer', textArabic: 'أستغفر الله', textEnglish: 'I seek forgiveness from Allah.', reference: 'After every prayer', targetCount: 3),
    Dhikr(id: 18, category: 'afterPrayer', textArabic: 'سبحان الله', textEnglish: 'Glory be to Allah.', targetCount: 33),
    Dhikr(id: 19, category: 'afterPrayer', textArabic: 'الحمد لله', textEnglish: 'All praise is for Allah.', targetCount: 33),
    Dhikr(id: 20, category: 'afterPrayer', textArabic: 'الله أكبر', textEnglish: 'Allah is the Greatest.', targetCount: 33),
    Dhikr(id: 21, category: 'afterPrayer', textArabic: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير', textEnglish: 'There is no deity except Allah alone, with no partner. His is the dominion and His is the praise, and He is over all things competent.', reference: 'After completing the 99', targetCount: 1),
    Dhikr(id: 22, category: 'afterPrayer', textArabic: 'اللهم أنت السلام ومنك السلام تباركت يا ذا الجلال والإكرام', textEnglish: 'O Allah, You are Peace and from You is peace. Blessed are You, O Owner of Majesty and Honor.', targetCount: 1),
    Dhikr(id: 43, category: 'afterPrayer', textArabic: 'اللهم أعني على ذكرك، وشكرك، وحسن عبادتك', textEnglish: 'O Allah, help me to remember You, to give thanks to You, and to worship You in the best manner.', targetCount: 1),
    Dhikr(id: 44, category: 'afterPrayer', textArabic: 'اللهم لا مانع لما أعطيت، ولا معطي لما منعت، ولا ينفع ذا الجد منك الجد', textEnglish: 'O Allah, none can prevent what You have bestowed and none can bestow what You have prevented, and no wealth or majesty can benefit anyone against Your Will.', targetCount: 1),
    Dhikr(id: 45, category: 'afterPrayer', textArabic: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير، لا حول ولا قوة إلا بالله، لا إله إلا الله، ولا نعبد إلا إياه، له النعمة وله الفضل وله الثناء الحسن، لا إله إلا الله مخلصين له الدين ولو كره الكافرون', textEnglish: 'There is no god but Allah alone, Who has no partner, His is the dominion and His is the praise, and He is Able to do all things. There is no might and no power except with Allah. There is no god but Allah, and we worship none but Him. To Him belongs all fortune, all grace, and all good praise. There is no god but Allah, to Whom we are sincere in religion even if the disbelievers detest it.', targetCount: 1),

    // ── Sleep Adhkar ────────────────────────────────────────
    Dhikr(id: 23, category: 'sleep', textArabic: 'باسمك اللهم أموت وأحيا', textEnglish: 'In Your name, O Allah, I die and I live.', targetCount: 1),
    Dhikr(id: 24, category: 'sleep', textArabic: 'سبحان الله', textEnglish: 'Glory be to Allah.', reference: 'Before sleep', targetCount: 33),
    Dhikr(id: 25, category: 'sleep', textArabic: 'الحمد لله', textEnglish: 'All praise is for Allah.', reference: 'Before sleep', targetCount: 33),
    Dhikr(id: 26, category: 'sleep', textArabic: 'الله أكبر', textEnglish: 'Allah is the Greatest.', reference: 'Before sleep', targetCount: 34),
    Dhikr(id: 27, category: 'sleep', textArabic: 'اللهم قني عذابك يوم تبعث عبادك', textEnglish: 'O Allah, protect me from Your punishment on the Day You resurrect Your servants.', targetCount: 3),
    Dhikr(id: 46, category: 'sleep', textArabic: 'باسمك ربي وضعت جنبي وبك أرفعه، فإن أمسكت نفسي فارحمها، وإن أرسلتها فاحفظها بما تحفظ به عبادك الصالحين', textEnglish: 'In Your name my Lord, I lie down and in Your name I rise, so if You should take my soul then have mercy upon it, and if You should return my soul then protect it as You protect Your righteous servants.', targetCount: 1),
    Dhikr(id: 47, category: 'sleep', textArabic: 'اللهم أسلمت نفسي إليك، وفوضت أمري إليك، ووجهت وجهي إليك، وألجأت ظهري إليك، رغبة ورهبة إليك، لا ملجأ ولا منجا منك إلا إليك، آمنت بكتابك الذي أنزلت، وبنبيك الذي أرسلت', textEnglish: 'O Allah, I submit my soul to You, and I entrust my affair to You, and I turn my face to You, and I depend upon You in hope and fear of You. There is no refuge and no escape from You except to You. I believe in Your Book which You have revealed, and in Your Prophet whom You have sent.', targetCount: 1),
    Dhikr(id: 48, category: 'sleep', textArabic: 'اللهم خلقت نفسي وأنت توفاها، لك مماتها ومحياها، إن أحييتها فاحفظها، وإن أمتها فاغفر لها، اللهم إني أسألك العافية', textEnglish: 'O Allah, You have created my soul and You take it back. Unto You is its death and its life. If You give it life then protect it, and if You cause it to die then forgive it. O Allah, I ask You for well-being.', targetCount: 1),

    // ── General Adhkar ──────────────────────────────────────
    Dhikr(id: 28, category: 'general', textArabic: 'لا حول ولا قوة إلا بالله', textEnglish: 'There is no might nor power except with Allah.', targetCount: 10),
    Dhikr(id: 29, category: 'general', textArabic: 'أستغفر الله', textEnglish: 'I seek forgiveness from Allah.', targetCount: 100),
    Dhikr(id: 30, category: 'general', textArabic: 'اللهم صل وسلم على نبينا محمد', textEnglish: 'O Allah, send blessings and peace upon our Prophet Muhammad.', targetCount: 10),
    Dhikr(id: 31, category: 'general', textArabic: 'سبحان الله وبحمده، سبحان الله العظيم', textEnglish: 'Glory be to Allah and praise Him. Glory be to Allah, the Most Great.', targetCount: 10),
    Dhikr(id: 32, category: 'general', textArabic: 'لا إله إلا الله', textEnglish: 'There is no deity except Allah.', targetCount: 100),
    Dhikr(id: 33, category: 'general', textArabic: 'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر', textEnglish: 'Glory be to Allah, all praise is for Allah, there is no deity except Allah, and Allah is the Greatest.', targetCount: 10),
    Dhikr(id: 34, category: 'general', textArabic: 'اللهم اغفر لي وارحمني واهدني وارزقني وعافني', textEnglish: 'O Allah, forgive me, have mercy on me, guide me, provide for me, and grant me well-being.', targetCount: 7),
    Dhikr(id: 35, category: 'general', textArabic: 'الحمد لله رب العالمين', textEnglish: 'All praise is for Allah, Lord of all worlds.', targetCount: 33),
    Dhikr(id: 49, category: 'general', textArabic: 'اللهم إني أسألك الجنة وأعوذ بك من النار', textEnglish: 'O Allah, I ask You for Paradise and I seek refuge in You from the Fire.', targetCount: 3),
    Dhikr(id: 50, category: 'general', textArabic: 'اللهم إني أعوذ بك من العجز والكسل، والجبن والبخل، والهرم وعذاب القبر، اللهم آت نفسي تقواها، وزكها أنت خير من زكاها، أنت وليها ومولاها', textEnglish: 'O Allah, I seek refuge in You from incapacity and laziness, from cowardice and miserliness, from senility and the punishment of the grave. O Allah, grant my soul its piety and purify it, for You are the best to purify it. You are its Guardian and its Protector.', targetCount: 1),
    Dhikr(id: 51, category: 'general', textArabic: 'يا مقلب القلوب ثبت قلبي على دينك', textEnglish: 'O Turner of the hearts, make my heart firm upon Your religion.', targetCount: 3),
  ];

  // ── Hadith Data ────────────────────────────────────────────────────────────

  static const List<HadithCategory> hadithCategories = [
    HadithCategory(id: 'patience', nameAr: 'الصبر', nameEn: 'Patience', icon: Icons.favorite),
    HadithCategory(id: 'illness', nameAr: 'المرض والأجر', nameEn: 'Illness & Reward', icon: Icons.healing),
    HadithCategory(id: 'death', nameAr: 'الموت والآخرة', nameEn: 'Death & Afterlife', icon: Icons.nights_stay),
    HadithCategory(id: 'mercy', nameAr: 'الرحمة والمغفرة', nameEn: 'Mercy & Forgiveness', icon: Icons.spa),
  ];

  static const List<Hadith> allHadiths = [
    // ── Patience ────────────────────────────────────────────
    Hadith(id: 1, category: 'patience', textArabic: 'ما يصيب المسلم من نصب ولا وصب ولا هم ولا حزن ولا أذى ولا غم، حتى الشوكة يشاكها، إلا كفّر الله بها من خطاياه', textEnglish: 'No fatigue, illness, anxiety, sorrow, harm or grief befalls a Muslim, even the prick of a thorn, except that Allah expiates some of his sins thereby.', source: 'Sahih Bukhari & Muslim'),
    Hadith(id: 2, category: 'patience', textArabic: 'عجبًا لأمر المؤمن، إن أمره كله خير، وليس ذلك لأحد إلا للمؤمن: إن أصابته سراء شكر فكان خيرًا له، وإن أصابته ضراء صبر فكان خيرًا له', textEnglish: 'How wonderful is the affair of the believer, for his affairs are all good. If something good happens to him, he is thankful for it and that is good for him. If something bad happens to him, he bears it with patience and that is good for him.', source: 'Sahih Muslim'),
    Hadith(id: 3, category: 'patience', textArabic: 'إن عظم الجزاء مع عظم البلاء، وإن الله إذا أحب قومًا ابتلاهم', textEnglish: 'The greatest reward comes with the greatest trial. When Allah loves a people, He tests them.', source: 'Tirmidhi'),
    Hadith(id: 4, category: 'patience', textArabic: 'ما يزال البلاء بالمؤمن والمؤمنة في نفسه وولده وماله حتى يلقى الله وما عليه خطيئة', textEnglish: 'Trials will continue to befall the believing man and woman in their self, children, and wealth until they meet Allah with no sin remaining.', source: 'Tirmidhi'),
    Hadith(id: 5, category: 'patience', textArabic: 'إنما الصبر عند الصدمة الأولى', textEnglish: 'True patience is at the first stroke of calamity.', source: 'Sahih Bukhari & Muslim'),
    Hadith(id: 6, category: 'patience', textArabic: 'ما من عبد تصيبه مصيبة فيقول: إنا لله وإنا إليه راجعون، اللهم أجرني في مصيبتي وأخلف لي خيرًا منها، إلا أجره الله في مصيبته وأخلف له خيرًا منها', textEnglish: 'No servant is afflicted with a calamity and says "To Allah we belong and to Him we shall return. O Allah, reward me in my calamity and replace it with something better" except that Allah rewards him and replaces it with something better.', source: 'Sahih Muslim'),

    // ── Illness & Reward ────────────────────────────────────
    Hadith(id: 7, category: 'illness', textArabic: 'ما من مسلم يصيبه أذى، شوكة فما فوقها، إلا كفّر الله بها سيئاته، كما تحط الشجرة ورقها', textEnglish: 'No Muslim is afflicted with any harm, even if it were the prick of a thorn, but that Allah expiates his sins because of that, as a tree sheds its leaves.', source: 'Sahih Bukhari'),
    Hadith(id: 8, category: 'illness', textArabic: 'إذا مرض العبد أو سافر كتب له مثل ما كان يعمل مقيمًا صحيحًا', textEnglish: 'When a servant falls ill or travels, then he will get a reward similar to that which he used to get for his good deeds when he was healthy and at home.', source: 'Sahih Bukhari'),
    Hadith(id: 9, category: 'illness', textArabic: 'ما من مسلم يُشاك شوكة فما فوقها إلا كُتبت له بها درجة ومُحيت عنه بها خطيئة', textEnglish: 'No Muslim is pricked by a thorn or anything worse, except that a rank is written for him and a sin is erased thereby.', source: 'Sahih Muslim'),
    Hadith(id: 10, category: 'illness', textArabic: 'إن الله إذا أحب عبدًا ابتلاه، فمن رضي فله الرضا، ومن سخط فله السخط', textEnglish: 'When Allah loves a servant, He tests him. Whoever is content shall have contentment, and whoever is discontent shall have discontent.', source: 'Tirmidhi'),
    Hadith(id: 11, category: 'illness', textArabic: 'عودوا المريض واتبعوا الجنائز تذكركم الآخرة', textEnglish: 'Visit the sick and follow the funeral processions; they will remind you of the Hereafter.', source: 'Ahmad'),
    Hadith(id: 12, category: 'illness', textArabic: 'من عاد مريضًا لم يزل في خرفة الجنة حتى يرجع', textEnglish: 'Whoever visits a sick person is plucking the fruits of Paradise until he returns.', source: 'Sahih Muslim'),

    // ── Death & Afterlife ───────────────────────────────────
    Hadith(id: 13, category: 'death', textArabic: 'إذا مات الإنسان انقطع عنه عمله إلا من ثلاثة: إلا من صدقة جارية، أو علم ينتفع به، أو ولد صالح يدعو له', textEnglish: 'When a person dies, his deeds come to an end except for three: ongoing charity, beneficial knowledge, or a righteous child who prays for him.', source: 'Sahih Muslim'),
    Hadith(id: 14, category: 'death', textArabic: 'إن الله ليرفع الدرجة للعبد الصالح في الجنة فيقول: يا رب أنى لي هذه؟ فيقول: باستغفار ولدك لك', textEnglish: 'Allah will raise the status of His righteous servant in Paradise and he will say: O Lord, how did I earn this? He will say: Through your child seeking forgiveness for you.', source: 'Ahmad'),
    Hadith(id: 15, category: 'death', textArabic: 'من قرأ سورة يس على موتاه يسّر الله عليه', textEnglish: 'Whoever recites Surah Ya-Sin, Allah will ease matters for him.', source: 'Ahmad'),
    Hadith(id: 16, category: 'death', textArabic: 'القبر أول منازل الآخرة، فإن نجا منه فما بعده أيسر منه، وإن لم ينج منه فما بعده أشد منه', textEnglish: 'The grave is the first stage of the Hereafter. If one is saved from it, what comes after is easier. If one is not saved, what comes after is harder.', source: 'Tirmidhi'),
    Hadith(id: 17, category: 'death', textArabic: 'أكثروا ذكر هادم اللذات: الموت', textEnglish: 'Frequently remember the destroyer of pleasures: death.', source: 'Tirmidhi'),
    Hadith(id: 18, category: 'death', textArabic: 'ما من ميت يموت فيقوم باكيه فيقول: واجبلاه واسنداه، إلا وُكِّل به ملكان يلهزانه: أهكذا كنت؟', textEnglish: 'No one dies and a mourner stands wailing except that two angels are appointed to rebuke the dead — therefore let people pray for the deceased instead.', source: 'Tirmidhi'),

    // ── Mercy & Forgiveness ─────────────────────────────────
    Hadith(id: 19, category: 'mercy', textArabic: 'قال الله تعالى: أنا عند ظن عبدي بي، وأنا معه إذا ذكرني', textEnglish: 'Allah says: I am as My servant thinks of Me, and I am with him when he remembers Me.', source: 'Sahih Bukhari & Muslim'),
    Hadith(id: 20, category: 'mercy', textArabic: 'إن الله تعالى يبسط يده بالليل ليتوب مسيء النهار، ويبسط يده بالنهار ليتوب مسيء الليل', textEnglish: 'Allah extends His Hand at night so that the sinners of the day may repent, and extends His Hand during the day so that the sinners of the night may repent.', source: 'Sahih Muslim'),
    Hadith(id: 21, category: 'mercy', textArabic: 'لله أفرح بتوبة عبده من أحدكم سقط على بعيره وقد أضله في أرض فلاة', textEnglish: 'Allah is more pleased with the repentance of His servant than one of you who found his lost camel in the desert.', source: 'Sahih Muslim'),
    Hadith(id: 22, category: 'mercy', textArabic: 'إن رحمتي غلبت غضبي', textEnglish: 'Indeed My mercy prevails over My wrath.', source: 'Sahih Bukhari & Muslim'),
    Hadith(id: 23, category: 'mercy', textArabic: 'جعل الله الرحمة مائة جزء فأمسك عنده تسعة وتسعين جزءًا وأنزل في الأرض جزءًا واحدًا', textEnglish: 'Allah divided mercy into one hundred parts. He kept ninety-nine with Himself and sent down one part to the earth.', source: 'Sahih Bukhari'),
    Hadith(id: 24, category: 'mercy', textArabic: 'يا عبادي إنكم تخطئون بالليل والنهار وأنا أغفر الذنوب جميعًا فاستغفروني أغفر لكم', textEnglish: 'O My servants, you sin by night and by day, and I forgive all sins, so seek forgiveness from Me and I shall forgive you.', source: 'Sahih Muslim'),
    Hadith(id: 25, category: 'patience', textArabic: 'من يرد الله به خيراً يصب منه', textEnglish: 'If Allah wants to do good to somebody, He afflicts him with trials.', source: 'Sahih Bukhari'),
    Hadith(id: 26, category: 'mercy', textArabic: 'الراحمون يرحمهم الرحمن، ارحموا من في الأرض يرحمكم من في السماء', textEnglish: 'The merciful will be shown mercy by the Most Merciful. Have mercy on those on earth, and the One in the heavens will have mercy on you.', source: 'Tirmidhi'),
    Hadith(id: 27, category: 'mercy', textArabic: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن: سبحان الله وبحمده، سبحان الله العظيم', textEnglish: 'Two words are light on the tongue, heavy on the balance, and beloved to the Most Merciful: Glory be to Allah and praise Him, Glory be to Allah the Almighty.', source: 'Sahih Bukhari & Muslim'),
    Hadith(id: 28, category: 'patience', textArabic: 'خيركم خيركم لأهله، وأنا خيركم لأهلي', textEnglish: 'The best of you are those who are best to their families, and I am the best of you to my family.', source: 'Tirmidhi'),
    Hadith(id: 29, category: 'mercy', textArabic: 'خيركم من تعلم القرآن وعلمه', textEnglish: 'The best of you is he who learns the Quran and teaches it.', source: 'Sahih Bukhari'),
    Hadith(id: 30, category: 'mercy', textArabic: 'الطهور شطر الإيمان', textEnglish: 'Purity is half of faith.', source: 'Sahih Muslim'),
    Hadith(id: 31, category: 'mercy', textArabic: 'والكلمة الطيبة صدقة', textEnglish: 'A good word is charity.', source: 'Sahih Bukhari & Muslim'),
    Hadith(id: 32, category: 'mercy', textArabic: 'لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه', textEnglish: 'None of you truly believes until he loves for his brother what he loves for himself.', source: 'Sahih Bukhari & Muslim'),
  ];

  // ── Duaa Data ──────────────────────────────────────────────────────────────

  static const List<Map<String, String>> duaas = [
    // ── From the Sunnah (Janazah prayer) ──
    {'ar': 'اللهم اغفر لها وارحمها، وعافها واعف عنها', 'en': 'O Allah, forgive her, have mercy on her, and pardon her.'},
    {'ar': 'اللهم أكرم نزلها، ووسع مدخلها', 'en': 'O Allah, honor her abode and widen her entrance.'},
    {'ar': 'اللهم نقها من الذنوب والخطايا كما ينقى الثوب الأبيض من الدنس', 'en': 'O Allah, cleanse her of sins as white cloth is cleansed of stains.'},
    {'ar': 'اللهم أبدلها دارًا خيرًا من دارها وأهلًا خيرًا من أهلها', 'en': 'O Allah, give her a home better than her home and a family better than her family.'},
    {'ar': 'اللهم اجعل قبرها روضة من رياض الجنة', 'en': 'O Allah, make her grave a garden from the gardens of Paradise.'},
    {'ar': 'اللهم آنس وحشتها وارحم غربتها', 'en': 'O Allah, comfort her loneliness and have mercy on her alienation.'},
    {'ar': 'اللهم أدخلها الجنة من غير مناقشة حساب ولا سابقة عذاب', 'en': 'O Allah, admit her into Paradise without a reckoning or preceding punishment.'},
    {'ar': 'اللهم إن كانت محسنة فزد في حسناتها، وإن كانت مسيئة فتجاوز عن سيئاتها', 'en': 'O Allah, if she was a doer of good, then increase her good deeds, and if she was a wrongdoer, then overlook her bad deeds.'},
    {'ar': 'اللهم يمن كتابها، ويسر حسابها، وثقل بالحسنات ميزانها', 'en': 'O Allah, give her her book in her right hand, make her accounting easy, and make her scale of good deeds heavy.'},
    {'ar': 'اللهم اجعلها من الذين سعدوا في الجنة خالدين فيها ما دامت السماوات والأرض', 'en': 'O Allah, make her among those who are happy in Paradise, abiding therein as long as the heavens and the earth endure.'},
    // ── Additional authentic duaas for the deceased ──
    {'ar': 'اللهم اغسلها بالماء والثلج والبرد', 'en': 'O Allah, wash her with water, snow, and hail.'},
    {'ar': 'اللهم افسح لها في قبرها ونور لها فيه', 'en': 'O Allah, make her grave spacious and illuminate it for her.'},
    {'ar': 'اللهم اجعل ما أصابها رفعة في درجاتها وكفارة لسيئاتها', 'en': 'O Allah, make what befell her a raise in her ranks and an expiation for her sins.'},
    {'ar': 'اللهم ألحقها بالصالحين واجعلها من أهل اليمين', 'en': 'O Allah, join her with the righteous and make her from the people of the right.'},
    {'ar': 'اللهم لا تحرمنا أجرها ولا تفتنا بعدها واغفر لنا ولها', 'en': 'O Allah, do not deprive us of her reward, do not put us to trial after her, and forgive us and her.'},
    {'ar': 'اللهم ثبتها عند السؤال واجعل قبرها نورًا', 'en': 'O Allah, make her firm at the time of questioning and make her grave a light.'},
    {'ar': 'اللهم اغفر لحيِّنا وميتنا، وصغيرنا وكبيرنا، وذكرنا وأنثانا، وشاهدنا وغائبنا', 'en': 'O Allah, forgive the living and the dead among us, the young and old, male and female, and those present and absent.'},
    {'ar': 'اللهم من أحييته منا فأحيه على الإسلام، ومن توفيته منا فتوفه على الإيمان', 'en': 'O Allah, whoever You keep alive among us, let him live upon Islam, and whoever You cause to die, let him die upon faith.'},
    {'ar': 'اللهم اجعلها شفيعة لأهلها يوم القيامة', 'en': 'O Allah, make her an intercessor for her family on the Day of Judgment.'},
    {'ar': 'اللهم ارزقها الفردوس الأعلى من الجنة بلا حساب ولا عذاب', 'en': 'O Allah, grant her the highest level of Paradise without reckoning or punishment.'},
  ];

}

/// Helper class for Hadith categories, since it was private in the screen
class HadithCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;

  const HadithCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
  });
}
