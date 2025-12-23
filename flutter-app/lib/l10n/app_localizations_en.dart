// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tale Generator';

  @override
  String get appSubtitle => 'Create magical stories for your children';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get createAccount => 'Create Account';

  @override
  String get startCreatingMagicalTales => 'Start creating magical tales';

  @override
  String get email => 'Email';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterAValidEmail => 'Please enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Password must be at least 6 characters';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get alreadyHaveAnAccountSignIn => 'Already have an account? Sign In';

  @override
  String get dontHaveAnAccountSignUp => 'Don\'t have an account? Sign Up';

  @override
  String get pleaseCheckYourEmailToVerifyYourAccount =>
      'Please check your email to verify your account';

  @override
  String get error => 'Error';

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String get yourStories => 'Your Stories';

  @override
  String get createMagicalTales => 'Create magical tales';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get noStoriesYet => 'No stories yet';

  @override
  String get createYourFirstMagicalTale => 'Create your first magical tale';

  @override
  String get generateYourFirstStory => 'Generate Your First Story';

  @override
  String get stories => 'Stories';

  @override
  String get children => 'Children';

  @override
  String get profile => 'Profile';

  @override
  String get childrenTitle => 'Children';

  @override
  String get noChildrenAddedYet => 'No children added yet';

  @override
  String get addYourFirstChildToCreatePersonalizedStories =>
      'Add your first child to create personalized stories';

  @override
  String get addYourFirstChild => 'Add Your First Child';

  @override
  String get age => 'Age';

  @override
  String get deleteChild => 'Delete Child';

  @override
  String areYouSureYouWantToDelete(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get childDeleted => 'Child deleted';

  @override
  String get addChild => 'Add Child';

  @override
  String get addAChild => 'Add a Child';

  @override
  String get createPersonalizedStories => 'Create personalized stories';

  @override
  String get name => 'Name';

  @override
  String get enterChildsName => 'Enter child\'s name';

  @override
  String get pleaseEnterAName => 'Please enter a name';

  @override
  String get enterChildsAge => 'Enter child\'s age';

  @override
  String get pleaseEnterAnAge => 'Please enter an age';

  @override
  String get ageMustBeBetween1And18 => 'Age must be between 1 and 18';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get interests => 'Interests';

  @override
  String get interestsCommaSeparated => 'Interests (comma-separated)';

  @override
  String get interestsExample => 'e.g., reading, sports, music';

  @override
  String get save => 'Save';

  @override
  String get childAddedSuccessfully => 'Child added successfully';

  @override
  String get generateStory => 'Generate Story';

  @override
  String get createMagic => 'Create Magic';

  @override
  String get generateAPersonalizedStory => 'Generate a personalized story';

  @override
  String get storyType => 'Story Type';

  @override
  String get child => 'Child';

  @override
  String get hero => 'Hero';

  @override
  String get combined => 'Combined';

  @override
  String get language => 'Language';

  @override
  String get moral => 'Moral';

  @override
  String get selectChild => 'Select Child';

  @override
  String get noChildrenAvailablePleaseAddAChildFirst =>
      'No children available. Please add a child first.';

  @override
  String get childForStory => 'Child for story';

  @override
  String get storyLengthMinutes => 'Story Length (minutes)';

  @override
  String get enterStoryLengthInMinutesOptional =>
      'Enter story length in minutes (optional)';

  @override
  String get pleaseEnterAValidNumber => 'Please enter a valid number';

  @override
  String get pleaseSelectAChild => 'Please select a child';

  @override
  String get profileTitle => 'Profile';

  @override
  String get statistics => 'Statistics';

  @override
  String get storiesThisMonth => 'Stories this month';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get logout => 'Logout';

  @override
  String get logoutFromAccount => 'Logout from account';

  @override
  String get areYouSureYouWantToLogout => 'Are you sure you want to logout?';

  @override
  String get languageSettings => 'Language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get freeStories => 'Free Stories';

  @override
  String get browseFreeStories => 'Browse free stories';

  @override
  String get ageCategory => 'Age';

  @override
  String get noFreeStoriesFound => 'No free stories found';

  @override
  String get tryDifferentFilters => 'Try different filters';
}
