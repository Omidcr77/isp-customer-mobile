import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageProvider = NotifierProvider<LanguageController, String>(
  LanguageController.new,
);

class LanguageController extends Notifier<String> {
  @override
  String build() => 'en';
  void select(String value) => state = value;
}

class Words {
  Words(this.language);
  final String language;
  bool get rtl => language != 'en';
  String call(String key) =>
      copy[key]?[language == 'fa'
          ? 1
          : language == 'ps'
          ? 2
          : 0] ??
      key;
  static const copy = <String, List<String>>{
    'app': ['My Internet', 'اینترنت من', 'زما انټرنېټ'],
    'welcome': [
      'Your connection, at a glance.',
      'اینترنت شما در یک نگاه.',
      'ستاسو انټرنېټ په یوه نظر.',
    ],
    'login': ['Sign in', 'ورود', 'ننوتل'],
    'username': ['Username', 'نام کاربری', 'کارن نوم'],
    'password': ['Password', 'رمز عبور', 'پټنوم'],
    'server': ['Portal URL', 'آدرس پورتال', 'د پورټل پته'],
    'serverHelp': [
      'Use the /users/ address supplied by your ISP.',
      'آدرس /users/ ارائه‌شده توسط شرکت را وارد کنید.',
      'د شرکت لخوا ورکړل شوې /users/ پته وکاروئ.',
    ],
    'required': [
      'Required · maximum 32 characters',
      'الزامی · حداکثر ۳۲ حرف',
      'اړین · تر ۳۲ تورو',
    ],
    'http': [
      'I understand HTTP exposes my credentials. Use only on a trusted network or VPN.',
      'می‌دانم HTTP اطلاعات ورود را آشکار می‌کند. فقط در شبکه مورد اعتماد یا VPN استفاده شود.',
      'زه پوهېږم چې HTTP زما د ننوتلو معلومات ښکاره کوي. یوازې باوري شبکه یا VPN وکاروئ.',
    ],
    'dashboard': ['Overview', 'نمای کلی', 'لنډیز'],
    'service': ['Active service', 'سرویس فعال', 'فعال خدمت'],
    'traffic': ['Internet traffic', 'ترافیک اینترنت', 'د انټرنېټ مصرف'],
    'usage': ['Usage history', 'گزارش مصرف', 'د مصرف تاریخچه'],
    'balance': ['Balance & credit', 'موجودی و اعتبار', 'پاتې پیسې او اعتبار'],
    'payments': ['Payment history', 'سوابق پرداخت‌ها', 'د تادیاتو تاریخچه'],
    'packages': ['Available packages', 'بسته‌های موجود', 'شته بستې'],
    'reports': ['Reports', 'گزارش‌ها', 'راپورونه'],
    'documents': ['Documents', 'مدارک', 'اسناد'],
    'notifications': ['Notifications', 'اطلاعیه‌ها', 'خبرتیاوې'],
    'profile': ['Customer profile', 'مشخصات مشتری', 'د پېرودونکي معلومات'],
    'invoices': ['Invoices', 'صورت‌حساب‌ها', 'بلونه'],
    'settings': ['Settings', 'تنظیمات', 'تنظیمات'],
    'language': ['Language', 'زبان', 'ژبه'],
    'logout': [
      'Sign out & clear data',
      'خروج و پاک کردن اطلاعات',
      'وتل او معلومات پاکول',
    ],
    'retry': ['Try again', 'تلاش دوباره', 'بیا هڅه وکړئ'],
    'empty': [
      'No records returned',
      'اطلاعاتی دریافت نشد',
      'معلومات ترلاسه نه شول',
    ],
    'readonly': [
      'Read-only access',
      'دسترسی فقط خواندنی',
      'یوازې د لوستلو لاسرسی',
    ],
    'unsupported': [
      'This feature is not available in this version.',
      'این قابلیت در این نسخه در دسترس نیست.',
      'دا ځانګړنه په دې نسخه کې نشته.',
    ],
    'unverifiedContent': [
      'No records are available to display in this version.',
      'در این نسخه اطلاعاتی برای نمایش در دسترس نیست.',
      'په دې نسخه کې د ښودلو لپاره معلومات نشته.',
    ],
    'notificationsNote': [
      'Opening portal messages may mark them as read. This action has not been authorized.',
      'باز کردن پیام‌ها ممکن است آن‌ها را خوانده‌شده کند. این اقدام تأیید نشده است.',
      'د پیغامونو پرانیستل ښايي لوستل شوي یې کړي. د دې کار اجازه نه ده ورکړل شوې.',
    ],
    'invoicesNote': [
      'Invoice links were found in purchase code, but an invoice list was not verified.',
      'لینک صورت‌حساب در کد خرید یافت شد، اما فهرست آن تأیید نشد.',
      'د بل لینکونه د پېرود په کوډ کې وو، خو د بلونو لړ تایید نه شو.',
    ],
    'profileNote': [
      'Only identity fields shown on the dashboard are available.',
      'فقط اطلاعات هویتی صفحه نخست در دسترس است.',
      'یوازې د لومړۍ پاڼې پېژندنې معلومات شته.',
    ],
    'settingsNote': [
      'Sessions are cleared after 15 minutes. Sign out before switching servers. Purchases and account changes are unavailable.',
      'نشست پس از ۱۵ دقیقه پاک می‌شود. برای تغییر سرور خارج شوید. خرید و تغییر حساب غیرفعال است.',
      'ناسته له ۱۵ دقیقو وروسته پاکېږي. د سرور بدلولو لپاره ووځئ. پېرود او د حساب بدلون نشته.',
    ],
    'used': ['Used', 'مصرف شده', 'مصرف شوی'],
    'remaining': ['Remaining', 'باقیمانده', 'پاتې'],
    'hourly': [
      'Today by hour · GiB',
      'مصرف ساعتی امروز · GiB',
      'د نن ساعتنی مصرف · GiB',
    ],
    'dailyChart': [
      'Daily usage · GiB',
      'مصرف روزانه · GiB',
      'ورځنی مصرف · GiB',
    ],
    'monthlyChart': [
      'Monthly usage · GiB',
      'مصرف ماهانه · GiB',
      'میاشتنی مصرف · GiB',
    ],
    'drill': [
      'Choose a period for details',
      'برای جزئیات دوره را انتخاب کنید',
      'د جزیاتو لپاره موده وټاکئ',
    ],
    'back': ['All services', 'همه سرویس‌ها', 'ټول خدمتونه'],
    'ServiceHistory': ['Services', 'سرویس‌ها', 'خدمتونه'],
    'GiftHistory': ['Gifts', 'هدایا', 'ډالۍ'],
    'InstallmentHistory': ['Installments', 'اقساط', 'قسطونه'],
    'credentials': [
      'Sign-in rejected. Check your username and password.',
      'ورود رد شد. نام کاربری و رمز را بررسی کنید.',
      'ننوتل رد شول. کارن نوم او پټنوم وګورئ.',
    ],
    'unreachable': [
      'Cannot reach the portal. Check Wi-Fi or VPN and the server URL.',
      'پورتال در دسترس نیست. شبکه، VPN و آدرس را بررسی کنید.',
      'پورټل ته لاسرسی نشته. شبکه، VPN او پته وګورئ.',
    ],
    'timeout': [
      'The server took too long to respond. Try again.',
      'پاسخ سرور بیش از حد طول کشید. دوباره تلاش کنید.',
      'د سرور ځواب ډېر وځنډېد. بیا هڅه وکړئ.',
    ],
    'expired': [
      'Your session ended. Please sign in again.',
      'نشست پایان یافت. دوباره وارد شوید.',
      'ستاسو ناسته پای ته ورسېده. بیا ننوځئ.',
    ],
    'malformed': [
      'The portal format changed or returned unreadable data.',
      'قالب پورتال تغییر کرده یا داده قابل خواندن نیست.',
      'د پورټل بڼه بدله شوې یا معلومات نه لوستل کېږي.',
    ],
    'insecure': [
      'Use an HTTPS /users/ URL. HTTP is allowed only in an explicitly enabled debug build.',
      'از آدرس HTTPS با /users/ استفاده کنید. HTTP فقط در نسخه آزمایشی مجاز است.',
      'د HTTPS /users/ پته وکاروئ. HTTP یوازې په ازمایښتي بڼه کې اجازه لري.',
    ],
    'storage': [
      'Secure storage is unavailable. Please restart the app.',
      'ذخیره‌سازی امن در دسترس نیست. برنامه را دوباره باز کنید.',
      'خوندي زېرمه نشته. اپ بیا پرانیزئ.',
    ],
    'serverError': [
      'The portal could not complete the request.',
      'پورتال نتوانست درخواست را انجام دهد.',
      'پورټل غوښتنه بشپړه نه کړه.',
    ],
    'datesNote': [
      'Dates and currency retain the portal’s original format.',
      'تاریخ‌ها و واحد پول با قالب اصلی پورتال نمایش داده می‌شوند.',
      'نېټې او د پیسو واحد د پورټل په اصلي بڼه ښودل کېږي.',
    ],
    'daysNote': [
      'Remaining days are not calculated from an unverified calendar. See the service expiry date.',
      'روزهای باقیمانده با تقویم تأییدنشده محاسبه نمی‌شود. تاریخ پایان سرویس را ببینید.',
      'له ناتایید شوي کلیز څخه پاتې ورځې نه محاسبه کېږي. د پای نېټه وګورئ.',
    ],
  };
  String portal(String text) =>
      portalLabels[text]?[language == 'ps' ? 1 : 0] is String &&
          language != 'fa'
      ? portalLabels[text]![language == 'ps' ? 1 : 0]
      : text;
  static const portalLabels = <String, List<String>>{
    'مدت کل سرویس (روز)': ['Service duration (days)', 'د خدمت موده (ورځې)'],
    'مصرف شده (روز)': ['Elapsed days', 'تېرې ورځې'],
    'باقیمانده (روز)': ['Remaining days', 'پاتې ورځې'],
    'کاربر گرامی': ['Customer', 'پېرودونکی'],
    'کاربر گرامی :': ['Customer', 'پېرودونکی'],
    'نام کاربری': ['Username', 'کارن نوم'],
    'نام کاربری :': ['Username', 'کارن نوم'],
    'وضعیت اشتراک': ['Account status', 'د حساب حالت'],
    'مجوز اتصال': ['Connection permission', 'د اتصال اجازه'],
    'سرویس فعال': ['Active service', 'فعال خدمت'],
    'تاریخ شروع سرویس': ['Service start', 'د خدمت پیل'],
    'تاریخ پایان سرویس': ['Service expiry', 'د خدمت پای'],
    'آخرین بروز رسانی': ['Last updated', 'وروستی تازه کول'],
    'مانده ترافیک سرویس': ['Remaining service data', 'د خدمت پاتې ډاټا'],
    'مانده اضافه ترافیک': ['Remaining extra data', 'پاتې اضافي ډاټا'],
    'وضعیت اعتبار': ['Credit status', 'د اعتبار حالت'],
    'وضعیت هدیه': ['Gift status', 'د ډالۍ حالت'],
    'ترافیک محاسبه شده': ['Charged traffic', 'حساب شوی مصرف'],
    'ترافیک مصرفی رایگان': ['Free traffic', 'وړیا مصرف'],
    'ارسال واقعی': ['Actual upload', 'اصلي لېږل'],
    'دریافت واقعی': ['Actual download', 'اصلي ترلاسه کول'],
    'مجموع مصرف واقعی': ['Total actual traffic', 'ټول اصلي مصرف'],
    'زمان': ['Time', 'وخت'],
    'نام سرویس': ['Service name', 'د خدمت نوم'],
    'وضعیت': ['Status', 'حالت'],
    'وضعیت سرویس': ['Service status', 'د خدمت حالت'],
    'هزینه سرویس': ['Service cost', 'د خدمت بیه'],
    'ارزش افزوده': ['Tax', 'مالیه'],
    'تخفیف': ['Discount', 'تخفیف'],
    'هزینه پرداختی': ['Paid amount', 'ورکړل شوې پیسې'],
    'روش خرید': ['Purchase method', 'د پېرود طریقه'],
    'نوع': ['Type', 'ډول'],
    'سریال': ['Serial', 'شمېره'],
    'مبلغ': ['Amount', 'مبلغ'],
    'موجودی': ['Balance', 'پاتې پیسې'],
    'شماره تراکنش': ['Transaction number', 'د معاملې شمېره'],
    'سال': ['Year', 'کال'],
    'ماه': ['Month', 'میاشت'],
    'روز': ['Day', 'ورځ'],
    'جزئیات': ['Details', 'جزیات'],
    'مجموع ارسال واقعی': ['Total upload', 'ټول لېږل'],
    'مجموع دریافت واقعی': ['Total download', 'ټول ترلاسه کول'],
    'مجموع مجموع مصرف واقعی': ['Total traffic', 'ټول مصرف'],
  };
}

extension LocalWords on BuildContext {
  Words words(WidgetRef ref) => Words(ref.watch(languageProvider));
}
