import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Tale Generator'**
  String get appTitle;

  /// The application subtitle
  ///
  /// In en, this message translates to:
  /// **'Create magical stories for your children'**
  String get appSubtitle;

  /// Welcome back message
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Sign in prompt
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Create account title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Create account subtitle
  ///
  /// In en, this message translates to:
  /// **'Start creating magical tales'**
  String get startCreatingMagicalTales;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Link to sign in
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAnAccountSignIn;

  /// Link to sign up
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAnAccountSignUp;

  /// Email verification message
  ///
  /// In en, this message translates to:
  /// **'Please check your email to verify your account'**
  String get pleaseCheckYourEmailToVerifyYourAccount;

  /// Error prefix
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurred(String error);

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Your Stories'**
  String get yourStories;

  /// Home screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Create magical tales'**
  String get createMagicalTales;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Empty stories state title
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get noStoriesYet;

  /// Empty stories state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create your first magical tale'**
  String get createYourFirstMagicalTale;

  /// Generate first story button
  ///
  /// In en, this message translates to:
  /// **'Generate Your First Story'**
  String get generateYourFirstStory;

  /// Stories tab label
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get stories;

  /// Children tab label
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Children screen title
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get childrenTitle;

  /// Empty children state title
  ///
  /// In en, this message translates to:
  /// **'No children added yet'**
  String get noChildrenAddedYet;

  /// Empty children state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your first child to create personalized stories'**
  String get addYourFirstChildToCreatePersonalizedStories;

  /// Add first child button
  ///
  /// In en, this message translates to:
  /// **'Add Your First Child'**
  String get addYourFirstChild;

  /// Age label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// Delete child dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Child'**
  String get deleteChild;

  /// Delete child confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String areYouSureYouWantToDelete(String name);

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Child deleted success message
  ///
  /// In en, this message translates to:
  /// **'Child deleted'**
  String get childDeleted;

  /// Add child screen title
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild;

  /// Add child header title
  ///
  /// In en, this message translates to:
  /// **'Add a Child'**
  String get addAChild;

  /// Add child header subtitle
  ///
  /// In en, this message translates to:
  /// **'Create personalized stories'**
  String get createPersonalizedStories;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter child\'s name'**
  String get enterChildsName;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterAName;

  /// Age field hint
  ///
  /// In en, this message translates to:
  /// **'Enter child\'s age'**
  String get enterChildsAge;

  /// Age validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter an age'**
  String get pleaseEnterAnAge;

  /// Age range validation error
  ///
  /// In en, this message translates to:
  /// **'Age must be between 1 and 18'**
  String get ageMustBeBetween1And18;

  /// Gender field label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// Female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// Other gender option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Interests field label
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// Interests field hint
  ///
  /// In en, this message translates to:
  /// **'Interests (comma-separated)'**
  String get interestsCommaSeparated;

  /// Interests example
  ///
  /// In en, this message translates to:
  /// **'e.g., reading, sports, music'**
  String get interestsExample;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Child added success message
  ///
  /// In en, this message translates to:
  /// **'Child added successfully'**
  String get childAddedSuccessfully;

  /// Generate story screen title
  ///
  /// In en, this message translates to:
  /// **'Generate Story'**
  String get generateStory;

  /// Generate story header title
  ///
  /// In en, this message translates to:
  /// **'Create Magic'**
  String get createMagic;

  /// Generate story header subtitle
  ///
  /// In en, this message translates to:
  /// **'Generate a personalized story'**
  String get generateAPersonalizedStory;

  /// Story type field label
  ///
  /// In en, this message translates to:
  /// **'Story Type'**
  String get storyType;

  /// Child story type
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// Hero story type
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get hero;

  /// Combined story type
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get combined;

  /// Language field label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Moral field label
  ///
  /// In en, this message translates to:
  /// **'Moral'**
  String get moral;

  /// Select child field label
  ///
  /// In en, this message translates to:
  /// **'Select Child'**
  String get selectChild;

  /// No children available message
  ///
  /// In en, this message translates to:
  /// **'No children available. Please add a child first.'**
  String get noChildrenAvailablePleaseAddAChildFirst;

  /// Selected child label
  ///
  /// In en, this message translates to:
  /// **'Child for story'**
  String get childForStory;

  /// Story length field label
  ///
  /// In en, this message translates to:
  /// **'Story Length (minutes)'**
  String get storyLengthMinutes;

  /// Story length field hint
  ///
  /// In en, this message translates to:
  /// **'Enter story length in minutes (optional)'**
  String get enterStoryLengthInMinutesOptional;

  /// Number validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterAValidNumber;

  /// Child selection validation error
  ///
  /// In en, this message translates to:
  /// **'Please select a child'**
  String get pleaseSelectAChild;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Statistics section title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Monthly stories count label
  ///
  /// In en, this message translates to:
  /// **'Stories this month'**
  String get storiesThisMonth;

  /// Profile not found message
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// Profile loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout dialog title
  ///
  /// In en, this message translates to:
  /// **'Logout from account'**
  String get logoutFromAccount;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// Language settings label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Russian language option
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// Free stories tab label
  ///
  /// In en, this message translates to:
  /// **'Free Stories'**
  String get freeStories;

  /// Free stories screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Browse free stories'**
  String get browseFreeStories;

  /// Age category filter label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageCategory;

  /// Empty free stories state title
  ///
  /// In en, this message translates to:
  /// **'No free stories found'**
  String get noFreeStoriesFound;

  /// Empty free stories state subtitle
  ///
  /// In en, this message translates to:
  /// **'Try different filters'**
  String get tryDifferentFilters;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
