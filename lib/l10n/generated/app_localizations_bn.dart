// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'সেবার জানালা';

  @override
  String get signInTitle => 'সাইন ইন';

  @override
  String get phoneLabel => 'মোবাইল নম্বর';

  @override
  String get phoneHint => '01XXXXXXXXX';

  @override
  String get pinLabel => 'পিন';

  @override
  String get signInButton => 'সাইন ইন করুন';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String welcomeUser(String name) {
    return 'স্বাগতম, $name';
  }

  @override
  String get language => 'ভাষা';

  @override
  String get errRequired => 'এই ঘরটি পূরণ করতে হবে।';

  @override
  String get errPin => 'পিন ৪ থেকে ৬ সংখ্যার হতে হবে।';

  @override
  String get errNetwork => 'ইন্টারনেট সংযোগ নেই। সংযোগ দেখে আবার চেষ্টা করুন।';

  @override
  String get errTimeout => 'সার্ভার সাড়া দিতে দেরি করছে। আবার চেষ্টা করুন।';

  @override
  String get errPinInvalid => 'মোবাইল নম্বর বা পিন ভুল।';

  @override
  String get errAccountLocked =>
      'অনেকবার ভুল হয়েছে। কিছুক্ষণের জন্য আপনার অ্যাকাউন্ট বন্ধ।';

  @override
  String get errPhoneNotRegistered => 'এই নম্বরটি নিবন্ধিত নয়।';

  @override
  String get errRateLimited => 'অনেকবার চেষ্টা হয়েছে। একটু অপেক্ষা করুন।';

  @override
  String get errUnauthenticated =>
      'আপনার সেশনের মেয়াদ শেষ। আবার সাইন ইন করুন।';

  @override
  String get errGeneric => 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String errReference(String id) {
    return 'রেফারেন্স: $id';
  }

  @override
  String get aiSimulated => 'সিমুলেটেড এআই';

  @override
  String get aiLive => 'লাইভ এআই';

  @override
  String get navHome => 'হোম';

  @override
  String get navOpportunities => 'কর্মসূচি';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get searchHint => 'কর্মসূচি খুঁজুন';

  @override
  String get allCategories => 'সব';

  @override
  String get catScholarship => 'বৃত্তি';

  @override
  String get catHealthcare => 'স্বাস্থ্যসেবা';

  @override
  String get catAgriculture => 'কৃষি';

  @override
  String get catBusiness => 'ব্যবসা';

  @override
  String get catLegalAid => 'আইনি সহায়তা';

  @override
  String get catEmployment => 'কর্মসংস্থান';

  @override
  String get catFinancial => 'আর্থিক';

  @override
  String get catSocialWelfare => 'সমাজকল্যাণ';

  @override
  String get catTraining => 'প্রশিক্ষণ';

  @override
  String get catDisaster => 'দুর্যোগ ত্রাণ';

  @override
  String get catResearch => 'গবেষণা';

  @override
  String get eligEligible => 'আপনি যোগ্য হতে পারেন';

  @override
  String get eligPartial => 'আংশিক মিলেছে';

  @override
  String get eligNotEligible => 'মিলছে না';

  @override
  String get eligUnknown => 'আরও তথ্য দরকার';

  @override
  String eligScore(int score) {
    return '$score% মিল';
  }

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get noResults => 'কোনো কর্মসূচি পাওয়া যায়নি।';

  @override
  String get loadMoreFailed => 'আরও লোড করা যায়নি।';

  @override
  String perMonth(String amount) {
    return '$amount / মাস';
  }

  @override
  String perQuarter(String amount) {
    return '$amount / ত্রৈমাসিক';
  }

  @override
  String oneTime(String amount) {
    return '$amount এককালীন';
  }

  @override
  String amountOnly(String amount) {
    return '$amount';
  }

  @override
  String deadlineOn(String date) {
    return 'শেষ তারিখ: $date';
  }

  @override
  String get secDescription => 'এই কর্মসূচি সম্পর্কে';

  @override
  String get secBenefits => 'আপনি যা পাবেন';

  @override
  String get secHowToApply => 'কীভাবে আবেদন করবেন';

  @override
  String get secDocuments => 'যেসব কাগজ লাগবে';

  @override
  String get secWhyEligible => 'এই ফলাফলের কারণ';

  @override
  String get secProvider => 'প্রদানকারী';

  @override
  String get secTrust => 'তথ্য কতটা নির্ভরযোগ্য';

  @override
  String get requiredDoc => 'আবশ্যক';

  @override
  String get optionalDoc => 'ঐচ্ছিক';

  @override
  String get tipLabel => 'পরামর্শ';

  @override
  String get commonMistakeLabel => 'সাধারণ ভুল';

  @override
  String get verifUnverified => 'নমুনা তথ্য, এখনো যাচাই হয়নি';

  @override
  String get verifPending => 'সরকারি যাচাইয়ের অপেক্ষায়';

  @override
  String get verifVerified => 'যাচাইকৃত';

  @override
  String get verifOutdated => 'তথ্য পুরনো হতে পারে';

  @override
  String get verifDisputed => 'উৎস নিয়ে প্রশ্ন আছে — অফিসে জেনে নিন';

  @override
  String get confHigh => 'উচ্চ নির্ভরযোগ্যতা';

  @override
  String get confMedium => 'মাঝারি নির্ভরযোগ্যতা';

  @override
  String get confLow => 'কম নির্ভরযোগ্যতা';

  @override
  String get ruleMet => 'মিলেছে';

  @override
  String get ruleFailed => 'মিলছে না';

  @override
  String get ruleUnknown => 'জানা নেই';

  @override
  String get recommendedForYou => 'আপনার জন্য কর্মসূচি';

  @override
  String get noRecommendations =>
      'এখনো কোনো মিল নেই। ভালো ফলাফলের জন্য প্রোফাইল সম্পূর্ণ করুন।';

  @override
  String get browseAll => 'সব কর্মসূচি দেখুন';

  @override
  String get officeHours => 'অফিস সময়';

  @override
  String get phoneLabelShort => 'ফোন';

  @override
  String get processingTime => 'প্রক্রিয়াকরণের সময়';

  @override
  String get profileTitle => 'আপনার অ্যাকাউন্ট';

  @override
  String phoneValue(String phone) {
    return 'ফোন: $phone';
  }

  @override
  String districtValue(String district) {
    return 'জেলা: $district';
  }

  @override
  String get navAsk => 'জিজ্ঞাসা';

  @override
  String get chatTitle => 'জিজ্ঞাসা';

  @override
  String get chatHint => 'আপনার প্রশ্ন লিখুন';

  @override
  String get chatSend => 'পাঠান';

  @override
  String get chatNew => 'নতুন চ্যাট';

  @override
  String get chatHistory => 'আগের চ্যাট';

  @override
  String get chatNoHistory => 'এখনো কোনো আগের চ্যাট নেই।';

  @override
  String get chatEmptyTitle => 'কীভাবে সাহায্য করতে পারি?';

  @override
  String get chatEmptyBody =>
      'ভাতা, বৃত্তি, সহায়তা ও সেবা সম্পর্কে বাংলা বা ইংরেজিতে জিজ্ঞাসা করুন।';

  @override
  String get chatSuggestion1 =>
      'আমার স্বামী মারা গেছেন, আমি কী সহায়তা পেতে পারি?';

  @override
  String get chatSuggestion2 => 'আমি একজন কৃষক, কী কী সুবিধা আছে?';

  @override
  String get chatSuggestion3 => 'ছাত্রদের জন্য বৃত্তি আছে?';

  @override
  String get chatNotSent => 'পাঠানো যায়নি। আবার চেষ্টা করতে ট্যাপ করুন।';

  @override
  String get chatSending => 'পাঠানো হচ্ছে…';

  @override
  String get chatThinking => 'কর্মসূচি খোঁজা হচ্ছে…';

  @override
  String get chatSimulatedNote =>
      'সিমুলেটেড এআই। যোগ্যতার সিদ্ধান্ত লাইভ এআই-এর মতোই।';

  @override
  String get chatNextStep => 'পরবর্তী ধাপ';

  @override
  String get chatViewProgramme => 'কর্মসূচি দেখুন';

  @override
  String get errAiUnavailable =>
      'সহকারী ব্যস্ত ছিল বা সময় বেশি লেগেছে। আপনার বার্তা রাখা আছে। আবার চেষ্টা করুন।';

  @override
  String get voiceStart => 'বলুন';

  @override
  String get voiceStop => 'থামুন ও যা বলেছি তা ব্যবহার করুন';

  @override
  String get voiceListening => 'শুনছি… শেষ হলে ট্যাপ করুন';

  @override
  String get voiceTranscribing => 'আপনি কী বলেছেন বুঝছি…';

  @override
  String get voiceErrPermission =>
      'মাইক্রোফোনের অনুমতি বন্ধ আছে। ফোনের সেটিংসে চালু করুন, অথবা লিখুন।';

  @override
  String get voiceErrUnavailable =>
      'এই ফোনে বা সার্ভারে ভয়েস টাইপিং চালু নেই। অনুগ্রহ করে লিখুন।';

  @override
  String get voiceErrLocale =>
      'এই ফোনে বাংলা বক্তৃতা প্যাক নেই। গুগল সেটিংসে ইনস্টল করুন, অথবা লিখুন।';

  @override
  String get voiceErrNoSpeech =>
      'কিছু শুনতে পাইনি। মাইক্রোফোনে ট্যাপ করে আবার চেষ্টা করুন।';

  @override
  String get voiceErrServer =>
      'আপনার কণ্ঠ লেখায় রূপান্তর করা যায়নি। আবার চেষ্টা করুন, অথবা লিখুন।';

  @override
  String get readAloud => 'পড়ে শোনান';

  @override
  String get stopReading => 'পড়া থামান';

  @override
  String get navSaved => 'আমার তালিকা';

  @override
  String get savedTab => 'সংরক্ষিত';

  @override
  String get plansTab => 'পরিকল্পনা';

  @override
  String get savedEmpty =>
      'এখনো কিছু সংরক্ষণ করা হয়নি। কোনো কর্মসূচির বুকমার্কে ট্যাপ করলে এখানে থাকবে।';

  @override
  String get plansEmpty =>
      'এখনো কোনো পরিকল্পনা নেই। কর্মসূচি খুলে \"পরিকল্পনা করুন\" চাপলে ধাপে ধাপে তালিকা পাবেন।';

  @override
  String get saveProgramme => 'সংরক্ষণ করুন';

  @override
  String get unsaveProgramme => 'সংরক্ষণ থেকে সরান';

  @override
  String get savedToast => 'সংরক্ষিত হয়েছে';

  @override
  String get removedToast => 'সংরক্ষণ থেকে সরানো হয়েছে';

  @override
  String get undo => 'ফিরিয়ে আনুন';

  @override
  String get makePlan => 'পরিকল্পনা করুন';

  @override
  String get openPlan => 'আমার পরিকল্পনা খুলুন';

  @override
  String get changeStatus => 'এই বিষয়ে আপনি কোথায় আছেন?';

  @override
  String get allStatuses => 'সব';

  @override
  String get statusInterested => 'আগ্রহী';

  @override
  String get statusPreparing => 'প্রস্তুতি চলছে';

  @override
  String get statusDocsReady => 'কাগজপত্র তৈরি';

  @override
  String get statusApplied => 'আবেদন করেছি';

  @override
  String get statusUnderReview => 'যাচাই চলছে';

  @override
  String get statusApproved => 'অনুমোদিত';

  @override
  String get statusRejected => 'অনুমোদিত হয়নি';

  @override
  String get statusCompleted => 'সম্পন্ন';

  @override
  String progressOf(int done, int total) {
    return '$totalটির মধ্যে $doneটি সম্পন্ন';
  }

  @override
  String get priorityHigh => 'জরুরি';

  @override
  String get priorityMedium => 'মাঝারি গুরুত্ব';

  @override
  String get priorityLow => 'কম গুরুত্ব';

  @override
  String dueOn(String date) {
    return 'শেষ তারিখ $date';
  }

  @override
  String minutesShort(int n) {
    return '$n মিনিট';
  }

  @override
  String get taskUpdateFailed =>
      'এই ধাপটি হালনাগাদ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get planTitle => 'আপনার পরিকল্পনা';

  @override
  String get markDone => 'সম্পন্ন করুন';

  @override
  String get markNotDone => 'সম্পন্ন নয়';

  @override
  String get createAccount => 'নতুন অ্যাকাউন্ট খুলুন';

  @override
  String get forgotPin => 'পিন ভুলে গেছেন?';

  @override
  String get signInWithCode => 'কোড দিয়ে সাইন ইন করুন';

  @override
  String get haveAccount => 'আগে থেকেই অ্যাকাউন্ট আছে? সাইন ইন করুন';

  @override
  String get registerTitle => 'আপনার অ্যাকাউন্ট খুলুন';

  @override
  String get resetPinTitle => 'নতুন পিন দিন';

  @override
  String get otpLoginTitle => 'কোড দিয়ে সাইন ইন';

  @override
  String get sendCode => 'কোড পাঠান';

  @override
  String codeSentTo(String phone) {
    return '$phone নম্বরে ৬ সংখ্যার একটি কোড পাঠানো হয়েছে।';
  }

  @override
  String get codeLabel => '৬ সংখ্যার কোড';

  @override
  String get nameLabel => 'আপনার নাম';

  @override
  String get nameHelp => 'জাতীয় পরিচয়পত্রে যেভাবে আছে';

  @override
  String get newPinLabel => 'একটি পিন দিন (৪ থেকে ৬ সংখ্যা)';

  @override
  String get confirmPinLabel => 'পিনটি আবার লিখুন';

  @override
  String get pinMismatch => 'দুটি পিন একই নয়।';

  @override
  String get errPhone => '01 দিয়ে শুরু ১১ সংখ্যার নম্বর দিন।';

  @override
  String get errName => 'আপনার নাম লিখুন (অন্তত ২ অক্ষর)।';

  @override
  String get errCode => '৬ সংখ্যার কোডটি লিখুন।';

  @override
  String resendIn(int seconds) {
    return '$seconds সেকেন্ড পরে আবার পাঠান';
  }

  @override
  String get resendCode => 'আবার কোড পাঠান';

  @override
  String devCodeLabel(String code) {
    return 'শুধু ডেভেলপমেন্টের জন্য। কোড: $code';
  }

  @override
  String get chooseLanguage => 'ভাষা';

  @override
  String get finishRegister => 'অ্যাকাউন্ট খুলুন';

  @override
  String get finishResetPin => 'পিন সংরক্ষণ করে সাইন ইন করুন';

  @override
  String get finishOtpLogin => 'সাইন ইন করুন';

  @override
  String get changeNumber => 'অন্য নম্বর ব্যবহার করুন';

  @override
  String get errValidation => 'আপনি যা লিখেছেন তা আবার দেখুন।';

  @override
  String get errOtpInvalid => 'কোডটি সঠিক নয়। দেখে আবার চেষ্টা করুন।';

  @override
  String get errOtpExpired => 'কোডটির মেয়াদ শেষ। নতুন কোড চান।';

  @override
  String get errOtpAttempts => 'অনেকবার ভুল কোড দেওয়া হয়েছে। নতুন কোড চান।';

  @override
  String get errPhoneExists => 'এই নম্বরে আগেই অ্যাকাউন্ট আছে। সাইন ইন করুন।';

  @override
  String get errPinWeak =>
      'এই পিনটি সহজেই অনুমান করা যায়। 1234 বা 1111-এর মতো পিন দেবেন না।';

  @override
  String get demoHeader => 'ডেমো অ্যাকাউন্ট (শুধু ডেভেলপমেন্ট বিল্ডে)';

  @override
  String get demoPickHint =>
      'ভূমিকা বেছে নিলে ফোন নম্বর ও পিন নিজে থেকে ভরে যাবে';

  @override
  String get demoChooseRole => 'ভূমিকা বেছে নিন';

  @override
  String demoRoleLabel(String role) {
    return 'ডেমো ভূমিকা: $role';
  }

  @override
  String get greetMorning => 'শুভ সকাল';

  @override
  String get greetAfternoon => 'শুভ দুপুর';

  @override
  String get greetEvening => 'শুভ সন্ধ্যা';

  @override
  String get homeSpeak => 'কথা বলে প্রশ্ন করুন';

  @override
  String get homeContinuePlan => 'আপনার পরিকল্পনা চালিয়ে যান';

  @override
  String homeNextStep(String task) {
    return 'পরের ধাপ: $task';
  }

  @override
  String homeSavedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি কর্মসূচি সংরক্ষিত',
    );
    return '$_temp0';
  }

  @override
  String get homeSavedBody =>
      'ধাপে ধাপে চেকলিস্ট পেতে একটির জন্য পরিকল্পনা করুন।';

  @override
  String get homeStartTitle => 'আপনি কোন সাহায্য পেতে পারেন জেনে নিন';

  @override
  String get homeStartBody =>
      'নিজের ভাষায় আপনার অবস্থা জানান। আমরা মিলে যাওয়া কর্মসূচি খুঁজে দেব।';

  @override
  String get homeStartCta => 'এখনই জিজ্ঞাসা করুন';

  @override
  String get quickAll => 'সব কর্মসূচি';

  @override
  String get homeCategories => 'বিষয় অনুযায়ী খুঁজুন';

  @override
  String get moreCategories => 'আরও';

  @override
  String get fewerCategories => 'কম দেখান';

  @override
  String get closingSoon => 'শিগগিরই শেষ হচ্ছে';

  @override
  String daysLeft(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'আর $daysString দিন',
      zero: 'আজই শেষ দিন',
    );
    return '$_temp0';
  }

  @override
  String get seeAll => 'সব দেখুন';

  @override
  String get keyBenefit => 'সুবিধা';

  @override
  String get keyDeadline => 'শেষ তারিখ';

  @override
  String get deadlinePassed => 'বন্ধ হয়ে গেছে';

  @override
  String get readMore => 'আরও পড়ুন';

  @override
  String get readLess => 'কম দেখান';

  @override
  String get callOffice => 'কল করুন';

  @override
  String get directions => 'পথ দেখুন';

  @override
  String get website => 'ওয়েবসাইট';

  @override
  String get applyOnline => 'অনলাইনে আবেদন করুন';

  @override
  String get secNearbyOffices => 'আপনার কাছের অফিস';

  @override
  String rulesSummary(int met, int total) {
    final intl.NumberFormat metNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String metString = metNumberFormat.format(met);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalStringটির মধ্যে $metStringটি শর্ত মিলেছে';
  }

  @override
  String get couldNotOpen => 'এটি খোলা গেল না। আবার চেষ্টা করুন।';

  @override
  String get sourceLabel => 'উৎস';

  @override
  String get appTagline => 'আপনার প্রাপ্য সরকারি সহায়তা খুঁজে নিন';

  @override
  String get welcomeBack => 'আবার স্বাগতম';

  @override
  String get signInSubtitle => 'মোবাইল নম্বর ও পিন দিয়ে সাইন ইন করুন।';

  @override
  String get showPin => 'পিন দেখান';

  @override
  String get hidePin => 'পিন লুকান';

  @override
  String get orDivider => 'অথবা';

  @override
  String get newHere => 'নতুন ব্যবহারকারী?';

  @override
  String get pinSafety => 'আপনার পিন কাউকে বলবেন না, অফিসের কর্মীকেও না।';

  @override
  String stepOf(int step, int total) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'ধাপ $stepString/$totalString';
  }

  @override
  String get codeWillBeSent =>
      'এই নম্বরে এসএমএসে ৬ সংখ্যার একটি কোড পাঠানো হবে।';

  @override
  String get registerSubtitle =>
      'এক মিনিটের মতো সময় লাগবে। শুধু মোবাইল নম্বর লাগবে।';

  @override
  String get resetPinSubtitle =>
      'নম্বরটি আপনার কিনা যাচাই করে নতুন পিন বেছে নিতে দেব।';

  @override
  String get otpLoginSubtitle => 'পিনের বদলে এককালীন কোড দিয়ে সাইন ইন করুন।';

  @override
  String get enterCodeTitle => 'কোডটি লিখুন';

  @override
  String get choosePinTitle => 'আপনার পিন বেছে নিন';

  @override
  String get change => 'বদলান';

  @override
  String get eligibleOnly => 'আমি পেতে পারি';

  @override
  String resultsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countStringটি কর্মসূচি',
    );
    return '$_temp0';
  }

  @override
  String get clearFilters => 'ফিল্টার মুছুন';

  @override
  String get clearSearch => 'খোঁজা মুছুন';

  @override
  String get noResultsHint => 'অন্য শব্দে খুঁজুন, বা কোনো ফিল্টার সরিয়ে দিন।';

  @override
  String get voiceSearch => 'বলে খুঁজুন';

  @override
  String get assistantName => 'সহায়তা সহকারী';

  @override
  String get today => 'আজ';

  @override
  String get yesterday => 'গতকাল';

  @override
  String get copy => 'কপি';

  @override
  String get copied => 'কপি হয়েছে';

  @override
  String get chatMicHint => 'বাংলা বা ইংরেজিতে বলতে মাইকে চাপ দিন';

  @override
  String get chatTryAsking => 'এভাবে জিজ্ঞাসা করুন';

  @override
  String get scrollToLatest => 'সর্বশেষ বার্তায় যান';

  @override
  String get openProgramme => 'খুলুন';

  @override
  String get toDoSection => 'করণীয়';

  @override
  String get doneSection => 'শেষ হয়েছে';

  @override
  String get overdue => 'সময় পেরিয়ে গেছে';

  @override
  String get planCompleteTitle => 'সব ধাপ শেষ!';

  @override
  String get planCompleteBody =>
      'চমৎকার। আবেদন করার পর আমার তালিকায় অবস্থা হালনাগাদ করুন, যাতে অগ্রগতি দেখতে পারেন।';

  @override
  String get gotIt => 'ঠিক আছে';

  @override
  String get updateStatus => 'অবস্থা হালনাগাদ করুন';

  @override
  String get yourActivity => 'আপনার কার্যক্রম';

  @override
  String get settingsSection => 'সেটিংস';

  @override
  String get textSize => 'লেখার আকার';

  @override
  String get textNormal => 'সাধারণ';

  @override
  String get textLarge => 'বড়';

  @override
  String get textLarger => 'আরও বড়';

  @override
  String get helpSection => 'সাহায্য';

  @override
  String get helpline => 'সরকারি হেল্পলাইন ৩৩৩';

  @override
  String get helplineBody => 'যেকোনো সরকারি সেবা সম্পর্কে ফোনে জানুন';

  @override
  String get aboutApp => 'সেবার জানালা সম্পর্কে';

  @override
  String get aboutBody =>
      'সেবার জানালা আপনাকে সেই সরকারি কর্মসূচিগুলো খুঁজে দেয় যেগুলো আপনি পেতে পারেন, কোন কাগজপত্র লাগবে তা জানায় এবং আবেদনের অগ্রগতি মনে রাখতে সাহায্য করে।\n\nযোগ্যতার ফলাফল একটি নির্দেশনা, চূড়ান্ত সিদ্ধান্ত নয়। কর্মসূচি পরিচালনাকারী অফিসই চূড়ান্ত সিদ্ধান্ত নেয়, তাই আবেদনের আগে অবশ্যই তাদের সঙ্গে নিশ্চিত হয়ে নিন।';

  @override
  String get signOutConfirmTitle => 'সাইন আউট করবেন?';

  @override
  String get signOutConfirmBody =>
      'আবার সাইন ইন করতে মোবাইল নম্বর ও পিন লাগবে।';

  @override
  String get cancel => 'বাতিল';

  @override
  String get homeTrustNote =>
      'তথ্য যেখানে সম্ভব সরকারি উৎস থেকে নেওয়া। আবেদনের আগে অবশ্যই অফিসে নিশ্চিত হয়ে নিন।';
}
