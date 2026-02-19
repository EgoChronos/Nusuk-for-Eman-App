// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نُسك لإيمان';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get quranTitle => 'القرآن الكريم';

  @override
  String get audioTitle => 'استمع للقرآن';

  @override
  String get dhikrTitle => 'الأذكار';

  @override
  String get hadithTitle => 'أحاديث نبوية';

  @override
  String get duaaTitle => 'دعاء';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String get listenFullQuran => 'استمع للقرآن كاملاً';

  @override
  String get todaysDhikr => 'أذكار اليوم';

  @override
  String get makeDuaa => 'ادعُ لها';

  @override
  String get giftedToSoul => 'هذا العمل هدية لروح إيمان محمد طايع';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get aboutApp => 'عن التطبيق';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get enableNotificationsDesc => 'تشغيل/إيقاف جميع التنبيهات';

  @override
  String get remindersSection => 'تذكيرات';

  @override
  String get morningAdhkar => 'أذكار الصباح';

  @override
  String get eveningAdhkar => 'أذكار المساء';

  @override
  String get sleepAdhkar => 'أذكار النوم';

  @override
  String get surahKahf => 'سورة الكهف';

  @override
  String get inspirationsSection => 'إلهامات';

  @override
  String get floatingContent => 'نفحات إيمانية';

  @override
  String get floatingContentDesc => 'آيات، أحاديث، وأدعية عشوائية خلال اليوم';

  @override
  String get frequency => 'التكرار';

  @override
  String get freqLow => 'قليل';

  @override
  String get freqMedium => 'متوسط';

  @override
  String get freqHigh => 'كثير';

  @override
  String get resetProgress => 'إعادة تعيين التقدم';

  @override
  String get resetProgressDesc => 'مسح جميع العدادات والإشارات المرجعية';

  @override
  String get resetConfirmTitle => 'هل أنت متأكد؟';

  @override
  String get resetConfirmContent =>
      'سيتم مسح جميع بيانات القراءة والعدادات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get reset => 'مسح';

  @override
  String get themeTitle => 'المظهر';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get darkModeDesc => 'تفعيل الوضع الليلي';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get fontSizeTitle => 'حجم الخط';

  @override
  String get manageNotifications => 'إدارة التنبيهات';

  @override
  String get manageNotificationsDesc => 'ضبط أوقات التذكير والمحتوى';

  @override
  String get myStats => 'إحصائياتي';

  @override
  String get ayahsRead => 'آية مقروءة';

  @override
  String get dhikrTasbeeh => 'ذكر وتسبيح';

  @override
  String get duaasMade => 'دعاء';

  @override
  String get listeningTime => 'وقت الاستماع';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get surahsTab => 'السور';

  @override
  String get bookmarksTab => 'العلامات المرجعية';

  @override
  String ayahCountLabel(int count) {
    return '$count آية مقروءة';
  }

  @override
  String get khatmaProgress => 'تقدم الختمة';

  @override
  String get newKhatma => 'ختمة جديدة';

  @override
  String get khatmaResetNote =>
      'يُحفظ تقدم القراءة تلقائيًا ويمكنك البدء بختمة جديدة يدويًا';

  @override
  String get searchQuranHint => 'ابحث عن سورة أو آية...';

  @override
  String get noBookmarksYet => 'لا توجد علامات مرجعية بعد';

  @override
  String get markSurahRead => 'تحديد السورة كمقروءة';

  @override
  String get alreadyFullyRead => 'مقروءة بالكامل';

  @override
  String get lovedByEman => 'كانت تحبها إيمان';

  @override
  String get continueFromLeftOff => 'تابع من حيث توقفت';

  @override
  String tasbeehToday(int count) {
    return '$count تسبيحة اليوم';
  }

  @override
  String get globalImpact => 'أثر جماعي';

  @override
  String get liveUpdatesDesc => 'إحصائيات مباشرة من جميع المستخدمين';

  @override
  String get lastSavedUpdate => 'آخر تحديث محفوظ';

  @override
  String get statQuran => 'القرآن الكريم';

  @override
  String ayahNumberHeader(int count) {
    return 'آية $count';
  }

  @override
  String get markAsRead => 'تحديد كمقروء';

  @override
  String get alreadyRead => 'مقروءة بالفعل';

  @override
  String get bookmarkAyah => 'حفظ الآية';

  @override
  String get removeBookmark => 'إزالة الحفظ';

  @override
  String get readUntilHere => 'قرأت حتى هنا';

  @override
  String get markPreviousAsRead => 'تحديد كل الآيات السابقة كمقروءة';

  @override
  String get surahMarkedRead => 'تم تحديد السورة كمقروءة بالكامل';

  @override
  String get permissionSetupTitle => 'إعدادات التشغيل';

  @override
  String get permissionSetupDesc =>
      'لضمان وصول الأذكار والمحتوى الإيماني في وقتها، يرجى تفعيل الصلاحيات التالية:';

  @override
  String get overlayPermissionTitle => 'الظهور فوق التطبيقات';

  @override
  String get overlayPermissionDesc =>
      'يسمح بظهور النافذة العائمة للأذكار على الشاشة.';

  @override
  String get batteryPermissionTitle => 'تجاهل قيود البطارية';

  @override
  String get batteryPermissionDesc =>
      'للسماح بتشغيل التطبيق في الخلفية لضمان الإشعارات';

  @override
  String get appearancePermissionTitle => 'صلاحيات ظهور التنبيهات';

  @override
  String get appearancePermissionDesc =>
      'تفعيل \"عرض النوافذ المنبثقة\" و\"العرض على قفل الشاشة\" لضمان عمل التطبيق بكفاءة.';

  @override
  String get allPermissionsGranted => 'رائع! جميع الصلاحيات مفعلة الآن';

  @override
  String permissionBannerAlert(int count) {
    return 'تنبيه: الإعداد غير مكتمل ($count/3) ←';
  }

  @override
  String get runSettings => 'إعدادات التشغيل';

  @override
  String get runSettingsDesc => 'لضمان وصول الإشعارات في الموعد المحدد';

  @override
  String get troubleshoot => 'فحص واختبار';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String nextPrayerLabel(String name) {
    return 'التالي: $name';
  }

  @override
  String get prayerTimesSettings => 'إعدادات مواقيت الصلاة';

  @override
  String get calculationMethods => 'طريقة الحساب والمذهب';

  @override
  String get locationError => 'صلاحية الموقع مرفوضة أو الخدمة معطلة';

  @override
  String get locationUnknown => 'موقع غير معروف';

  @override
  String get methodMWL => 'رابطة العالم الإسلامي';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodUmmAlQura => 'أم القرى (مكة المكرمة)';

  @override
  String get madhabShafi => 'شافعي، مالكي، حنبلي';

  @override
  String get madhabHanafi => 'حنفي';

  @override
  String get selectMethod => 'اختر طريقة الحساب';

  @override
  String get selectMadhab => 'اختر المذهب';

  @override
  String get athanSound => 'صوت الأذان';

  @override
  String get selectAthan => 'اختر صوت الأذان';

  @override
  String get prePrayerAlert => 'تنبيه قبل الصلاة';

  @override
  String get selectReminder => 'اختر مدة التنبيه';

  @override
  String get minutes => 'دقائق';

  @override
  String get sunriseAlert => 'تنبيه الشروق';

  @override
  String get enabled => 'مفعل';

  @override
  String get disabled => 'معطل';

  @override
  String get off => 'إيقاف';

  @override
  String get calculationMethodsHeader => 'إعدادات الحساب';

  @override
  String get notificationsHeader => 'إعدادات التنبيهات';

  @override
  String get prayerSchedule => 'جدول الصلوات';
}
