// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Shebar Janala';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneHint => '01XXXXXXXXX';

  @override
  String get pinLabel => 'PIN';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get language => 'Language';

  @override
  String get errRequired => 'This field is required.';

  @override
  String get errPin => 'Your PIN must be 4 to 6 digits.';

  @override
  String get errNetwork => 'No connection. Check your internet and try again.';

  @override
  String get errTimeout => 'The server is taking too long. Please try again.';

  @override
  String get errPinInvalid => 'Wrong mobile number or PIN.';

  @override
  String get errAccountLocked =>
      'Too many wrong attempts. Your account is locked for a while.';

  @override
  String get errPhoneNotRegistered => 'This number is not registered.';

  @override
  String get errRateLimited => 'Too many attempts. Please wait a moment.';

  @override
  String get errUnauthenticated =>
      'Your session has expired. Please sign in again.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String errReference(String id) {
    return 'Reference: $id';
  }

  @override
  String get aiSimulated => 'Simulated AI';

  @override
  String get aiLive => 'Live AI';

  @override
  String get navHome => 'Home';

  @override
  String get navOpportunities => 'Programmes';

  @override
  String get navProfile => 'Profile';

  @override
  String get searchHint => 'Search programmes';

  @override
  String get allCategories => 'All';

  @override
  String get catScholarship => 'Scholarship';

  @override
  String get catHealthcare => 'Healthcare';

  @override
  String get catAgriculture => 'Agriculture';

  @override
  String get catBusiness => 'Business';

  @override
  String get catLegalAid => 'Legal aid';

  @override
  String get catEmployment => 'Employment';

  @override
  String get catFinancial => 'Financial';

  @override
  String get catSocialWelfare => 'Social welfare';

  @override
  String get catTraining => 'Training';

  @override
  String get catDisaster => 'Disaster relief';

  @override
  String get catResearch => 'Research';

  @override
  String get eligEligible => 'You may qualify';

  @override
  String get eligPartial => 'Partly matches';

  @override
  String get eligNotEligible => 'Not a match';

  @override
  String get eligUnknown => 'Need more info';

  @override
  String eligScore(int score) {
    return '$score% match';
  }

  @override
  String get retry => 'Try again';

  @override
  String get noResults => 'No programmes found.';

  @override
  String get loadMoreFailed => 'Could not load more.';

  @override
  String perMonth(String amount) {
    return '$amount / month';
  }

  @override
  String perQuarter(String amount) {
    return '$amount / quarter';
  }

  @override
  String oneTime(String amount) {
    return '$amount one-time';
  }

  @override
  String amountOnly(String amount) {
    return '$amount';
  }

  @override
  String deadlineOn(String date) {
    return 'Deadline: $date';
  }

  @override
  String get secDescription => 'About this programme';

  @override
  String get secBenefits => 'What you get';

  @override
  String get secHowToApply => 'How to apply';

  @override
  String get secDocuments => 'Documents you need';

  @override
  String get secWhyEligible => 'Why this result';

  @override
  String get secProvider => 'Provided by';

  @override
  String get secTrust => 'How sure are we';

  @override
  String get requiredDoc => 'Required';

  @override
  String get optionalDoc => 'Optional';

  @override
  String get tipLabel => 'Tip';

  @override
  String get commonMistakeLabel => 'Common mistake';

  @override
  String get verifUnverified => 'Sample data, not yet verified';

  @override
  String get verifPending => 'Awaiting official check';

  @override
  String get verifVerified => 'Verified';

  @override
  String get verifOutdated => 'May be out of date';

  @override
  String get verifDisputed => 'Source disputed — check the office';

  @override
  String get confHigh => 'High confidence';

  @override
  String get confMedium => 'Medium confidence';

  @override
  String get confLow => 'Low confidence';

  @override
  String get ruleMet => 'Matches';

  @override
  String get ruleFailed => 'Does not match';

  @override
  String get ruleUnknown => 'Unknown';

  @override
  String get recommendedForYou => 'Programmes for you';

  @override
  String get noRecommendations =>
      'No matches yet. Complete your profile to get better results.';

  @override
  String get browseAll => 'Browse all programmes';

  @override
  String get officeHours => 'Office hours';

  @override
  String get phoneLabelShort => 'Phone';

  @override
  String get processingTime => 'Processing time';

  @override
  String get profileTitle => 'Your account';

  @override
  String phoneValue(String phone) {
    return 'Phone: $phone';
  }

  @override
  String districtValue(String district) {
    return 'District: $district';
  }

  @override
  String get navAsk => 'Ask';

  @override
  String get chatTitle => 'Ask';

  @override
  String get chatHint => 'Type your question';

  @override
  String get chatSend => 'Send';

  @override
  String get chatNew => 'New chat';

  @override
  String get chatHistory => 'Past chats';

  @override
  String get chatNoHistory => 'No past chats yet.';

  @override
  String get chatEmptyTitle => 'How can we help?';

  @override
  String get chatEmptyBody =>
      'Ask in Bangla or English about benefits, allowances, scholarships and services.';

  @override
  String get chatSuggestion1 => 'My husband passed away. What help can I get?';

  @override
  String get chatSuggestion2 => 'I am a farmer. What support is there?';

  @override
  String get chatSuggestion3 => 'Are there scholarships for students?';

  @override
  String get chatNotSent => 'Not sent. Tap to try again.';

  @override
  String get chatSending => 'Sending…';

  @override
  String get chatThinking => 'Looking for programmes…';

  @override
  String get chatSimulatedNote =>
      'Simulated AI. Eligibility decisions are the same as with live AI.';

  @override
  String get chatNextStep => 'Next step';

  @override
  String get chatViewProgramme => 'View programme';

  @override
  String get errAiUnavailable =>
      'The assistant is busy or took too long. Your message was kept. Please try again.';

  @override
  String get voiceStart => 'Speak';

  @override
  String get voiceStop => 'Stop and use what I said';

  @override
  String get voiceListening => 'Listening… tap to finish';

  @override
  String get voiceTranscribing => 'Working out what you said…';

  @override
  String get voiceErrPermission =>
      'Microphone access is off. Turn it on in your phone\'s settings, or type instead.';

  @override
  String get voiceErrUnavailable =>
      'Voice typing is not available on this phone or server. Please type instead.';

  @override
  String get voiceErrLocale =>
      'This phone has no Bangla speech pack installed. Install it in Google settings, or type instead.';

  @override
  String get voiceErrNoSpeech =>
      'We did not hear anything. Tap the microphone and try again.';

  @override
  String get voiceErrServer =>
      'Could not turn your voice into text. Please try again, or type.';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get stopReading => 'Stop reading';

  @override
  String get navSaved => 'My list';

  @override
  String get savedTab => 'Saved';

  @override
  String get plansTab => 'Plans';

  @override
  String get savedEmpty =>
      'Nothing saved yet. Tap the bookmark on a programme to keep it here.';

  @override
  String get plansEmpty =>
      'No plans yet. Open a programme and tap \"Make a plan\" to get a step-by-step checklist.';

  @override
  String get saveProgramme => 'Save';

  @override
  String get unsaveProgramme => 'Remove from saved';

  @override
  String get savedToast => 'Saved';

  @override
  String get removedToast => 'Removed from saved';

  @override
  String get undo => 'Undo';

  @override
  String get makePlan => 'Make a plan';

  @override
  String get openPlan => 'Open my plan';

  @override
  String get changeStatus => 'Where are you with this?';

  @override
  String get allStatuses => 'All';

  @override
  String get statusInterested => 'Interested';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusDocsReady => 'Documents ready';

  @override
  String get statusApplied => 'Applied';

  @override
  String get statusUnderReview => 'Under review';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Not approved';

  @override
  String get statusCompleted => 'Completed';

  @override
  String progressOf(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get priorityHigh => 'High priority';

  @override
  String get priorityMedium => 'Medium priority';

  @override
  String get priorityLow => 'Low priority';

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String get taskUpdateFailed =>
      'Could not update that step. Please try again.';

  @override
  String get planTitle => 'Your plan';

  @override
  String get markDone => 'Mark done';

  @override
  String get markNotDone => 'Mark not done';

  @override
  String get createAccount => 'Create an account';

  @override
  String get forgotPin => 'Forgot your PIN?';

  @override
  String get signInWithCode => 'Sign in with a code instead';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get resetPinTitle => 'Set a new PIN';

  @override
  String get otpLoginTitle => 'Sign in with a code';

  @override
  String get sendCode => 'Send code';

  @override
  String codeSentTo(String phone) {
    return 'We sent a 6-digit code to $phone.';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get nameLabel => 'Your name';

  @override
  String get nameHelp => 'As it appears on your National ID';

  @override
  String get newPinLabel => 'Choose a PIN (4 to 6 digits)';

  @override
  String get confirmPinLabel => 'Type the PIN again';

  @override
  String get pinMismatch => 'The two PINs are not the same.';

  @override
  String get errPhone => 'Enter an 11-digit number starting with 01.';

  @override
  String get errName => 'Enter your name (at least 2 letters).';

  @override
  String get errCode => 'Enter the 6-digit code.';

  @override
  String resendIn(int seconds) {
    return 'Send again in ${seconds}s';
  }

  @override
  String get resendCode => 'Send the code again';

  @override
  String devCodeLabel(String code) {
    return 'Development only. Code: $code';
  }

  @override
  String get chooseLanguage => 'Language';

  @override
  String get finishRegister => 'Create account';

  @override
  String get finishResetPin => 'Save PIN and sign in';

  @override
  String get finishOtpLogin => 'Sign in';

  @override
  String get changeNumber => 'Use a different number';

  @override
  String get errValidation => 'Please check what you entered.';

  @override
  String get errOtpInvalid => 'That code is not right. Check it and try again.';

  @override
  String get errOtpExpired => 'That code has expired. Ask for a new one.';

  @override
  String get errOtpAttempts => 'Too many wrong codes. Ask for a new one.';

  @override
  String get errPhoneExists =>
      'This number already has an account. Sign in instead.';

  @override
  String get errPinWeak =>
      'That PIN is too easy to guess. Avoid 1234 or repeated digits like 1111.';

  @override
  String get demoHeader => 'Demo accounts (development builds only)';

  @override
  String get demoPickHint => 'Pick a role to fill in the phone number and PIN';

  @override
  String get demoChooseRole => 'Choose a role';

  @override
  String demoRoleLabel(String role) {
    return 'Demo role: $role';
  }

  @override
  String get greetMorning => 'Good morning';

  @override
  String get greetAfternoon => 'Good afternoon';

  @override
  String get greetEvening => 'Good evening';

  @override
  String get homeSpeak => 'Speak your question';

  @override
  String get homeContinuePlan => 'Continue your plan';

  @override
  String homeNextStep(String task) {
    return 'Next: $task';
  }

  @override
  String homeSavedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString programmes saved',
      one: '1 programme saved',
    );
    return '$_temp0';
  }

  @override
  String get homeSavedBody =>
      'Make a plan for one to get a step-by-step checklist.';

  @override
  String get homeStartTitle => 'Find help you qualify for';

  @override
  String get homeStartBody =>
      'Tell us about your situation in your own words. We will find programmes that match.';

  @override
  String get homeStartCta => 'Ask now';

  @override
  String get quickAll => 'All programmes';

  @override
  String get homeCategories => 'Browse by category';

  @override
  String get moreCategories => 'More';

  @override
  String get fewerCategories => 'Less';

  @override
  String get closingSoon => 'Closing soon';

  @override
  String daysLeft(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days left',
      one: '1 day left',
      zero: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String get seeAll => 'See all';

  @override
  String get keyBenefit => 'Benefit';

  @override
  String get keyDeadline => 'Deadline';

  @override
  String get deadlinePassed => 'Closed';

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Show less';

  @override
  String get callOffice => 'Call';

  @override
  String get directions => 'Directions';

  @override
  String get website => 'Website';

  @override
  String get applyOnline => 'Apply online';

  @override
  String get secNearbyOffices => 'Offices near you';

  @override
  String rulesSummary(int met, int total) {
    final intl.NumberFormat metNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String metString = metNumberFormat.format(met);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$metString of $totalString conditions match';
  }

  @override
  String get couldNotOpen => 'Could not open this. Please try again.';

  @override
  String get sourceLabel => 'Source';

  @override
  String get appTagline => 'Find the government help you are entitled to';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in with your mobile number and PIN.';

  @override
  String get showPin => 'Show PIN';

  @override
  String get hidePin => 'Hide PIN';

  @override
  String get orDivider => 'or';

  @override
  String get newHere => 'New here?';

  @override
  String get pinSafety =>
      'Never share your PIN with anyone, not even office staff.';

  @override
  String stepOf(int step, int total) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Step $stepString of $totalString';
  }

  @override
  String get codeWillBeSent =>
      'We will send a 6-digit code to this number by SMS.';

  @override
  String get registerSubtitle =>
      'It takes about a minute. You only need your mobile number.';

  @override
  String get resetPinSubtitle =>
      'We will check this is your number, then you can choose a new PIN.';

  @override
  String get otpLoginSubtitle => 'Use a one-time code instead of your PIN.';

  @override
  String get enterCodeTitle => 'Enter the code';

  @override
  String get choosePinTitle => 'Choose your PIN';

  @override
  String get change => 'Change';

  @override
  String get eligibleOnly => 'I may qualify';

  @override
  String resultsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString programmes',
      one: '1 programme',
    );
    return '$_temp0';
  }

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noResultsHint => 'Try other words, or remove a filter.';

  @override
  String get voiceSearch => 'Search by voice';

  @override
  String get assistantName => 'Help assistant';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get chatMicHint => 'Tap the mic to speak in Bangla or English';

  @override
  String get chatTryAsking => 'Try asking';

  @override
  String get scrollToLatest => 'Go to latest message';

  @override
  String get openProgramme => 'Open';

  @override
  String get toDoSection => 'To do';

  @override
  String get doneSection => 'Done';

  @override
  String get overdue => 'Overdue';

  @override
  String get planCompleteTitle => 'All steps done!';

  @override
  String get planCompleteBody =>
      'Well done. When you have applied, update where you are in My list so you can follow it.';

  @override
  String get gotIt => 'Got it';

  @override
  String get updateStatus => 'Update status';

  @override
  String get yourActivity => 'Your activity';

  @override
  String get settingsSection => 'Settings';

  @override
  String get textSize => 'Text size';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get textLarger => 'Larger';

  @override
  String get helpSection => 'Help';

  @override
  String get helpline => 'Government helpline 333';

  @override
  String get helplineBody => 'Ask about any government service by phone';

  @override
  String get aboutApp => 'About Shebar Janala';

  @override
  String get aboutBody =>
      'Shebar Janala helps you find government programmes you may qualify for, learn what documents to bring, and keep track of your applications.\n\nEligibility results are a guide, not a decision. The office that runs a programme makes the final decision, so always confirm with them before you apply.';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'You will need your mobile number and PIN to sign in again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get homeTrustNote =>
      'Information comes from official sources where available. Always confirm with the office before you apply.';
}
