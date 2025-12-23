// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Генератор Сказок';

  @override
  String get appSubtitle => 'Создавайте волшебные истории для ваших детей';

  @override
  String get welcomeBack => 'С возвращением';

  @override
  String get signInToContinue => 'Войдите, чтобы продолжить';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get startCreatingMagicalTales => 'Начните создавать волшебные сказки';

  @override
  String get email => 'Email';

  @override
  String get pleaseEnterYourEmail => 'Пожалуйста, введите ваш email';

  @override
  String get pleaseEnterAValidEmail => 'Пожалуйста, введите корректный email';

  @override
  String get password => 'Пароль';

  @override
  String get pleaseEnterYourPassword => 'Пожалуйста, введите ваш пароль';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Пароль должен содержать минимум 6 символов';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Зарегистрироваться';

  @override
  String get alreadyHaveAnAccountSignIn => 'Уже есть аккаунт? Войти';

  @override
  String get dontHaveAnAccountSignUp => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get pleaseCheckYourEmailToVerifyYourAccount =>
      'Пожалуйста, проверьте вашу почту для подтверждения аккаунта';

  @override
  String get error => 'Ошибка';

  @override
  String errorOccurred(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get yourStories => 'Ваши истории';

  @override
  String get createMagicalTales => 'Создавайте волшебные сказки';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get retry => 'Повторить';

  @override
  String get noStoriesYet => 'Пока нет историй';

  @override
  String get createYourFirstMagicalTale =>
      'Создайте вашу первую волшебную сказку';

  @override
  String get generateYourFirstStory => 'Создать первую историю';

  @override
  String get stories => 'Истории';

  @override
  String get children => 'Дети';

  @override
  String get profile => 'Профиль';

  @override
  String get childrenTitle => 'Дети';

  @override
  String get noChildrenAddedYet => 'Пока нет детей';

  @override
  String get addYourFirstChildToCreatePersonalizedStories =>
      'Добавьте первого ребёнка, чтобы создавать персонализированные истории';

  @override
  String get addYourFirstChild => 'Добавить первого ребёнка';

  @override
  String get age => 'Возраст';

  @override
  String get deleteChild => 'Удалить ребёнка';

  @override
  String areYouSureYouWantToDelete(String name) {
    return 'Вы уверены, что хотите удалить $name?';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get childDeleted => 'Ребёнок удалён';

  @override
  String get addChild => 'Добавить ребёнка';

  @override
  String get addAChild => 'Добавить ребёнка';

  @override
  String get createPersonalizedStories =>
      'Создавайте персонализированные истории';

  @override
  String get name => 'Имя';

  @override
  String get enterChildsName => 'Введите имя ребёнка';

  @override
  String get pleaseEnterAName => 'Пожалуйста, введите имя';

  @override
  String get enterChildsAge => 'Введите возраст ребёнка';

  @override
  String get pleaseEnterAnAge => 'Пожалуйста, введите возраст';

  @override
  String get ageMustBeBetween1And18 => 'Возраст должен быть от 1 до 18 лет';

  @override
  String get gender => 'Пол';

  @override
  String get male => 'Мужской';

  @override
  String get female => 'Женский';

  @override
  String get other => 'Другой';

  @override
  String get interests => 'Интересы';

  @override
  String get interestsCommaSeparated => 'Интересы (через запятую)';

  @override
  String get interestsExample => 'например: чтение, спорт, музыка';

  @override
  String get save => 'Сохранить';

  @override
  String get childAddedSuccessfully => 'Ребёнок успешно добавлен';

  @override
  String get generateStory => 'Создать историю';

  @override
  String get createMagic => 'Создать магию';

  @override
  String get generateAPersonalizedStory =>
      'Создать персонализированную историю';

  @override
  String get storyType => 'Тип истории';

  @override
  String get child => 'Ребёнок';

  @override
  String get hero => 'Герой';

  @override
  String get combined => 'Комбинированная';

  @override
  String get language => 'Язык';

  @override
  String get moral => 'Мораль';

  @override
  String get selectChild => 'Выбрать ребёнка';

  @override
  String get noChildrenAvailablePleaseAddAChildFirst =>
      'Нет доступных детей. Пожалуйста, сначала добавьте ребёнка.';

  @override
  String get childForStory => 'Ребёнок для истории';

  @override
  String get storyLengthMinutes => 'Длина истории (минуты)';

  @override
  String get enterStoryLengthInMinutesOptional =>
      'Введите длину истории в минутах (необязательно)';

  @override
  String get pleaseEnterAValidNumber => 'Пожалуйста, введите корректное число';

  @override
  String get pleaseSelectAChild => 'Пожалуйста, выберите ребёнка';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get statistics => 'Статистика';

  @override
  String get storiesThisMonth => 'Историй в этом месяце';

  @override
  String get profileNotFound => 'Профиль не найден';

  @override
  String get errorLoadingProfile => 'Ошибка загрузки профиля';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutFromAccount => 'Выход из аккаунта';

  @override
  String get areYouSureYouWantToLogout => 'Вы уверены, что хотите выйти?';

  @override
  String get languageSettings => 'Язык';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get freeStories => 'Бесплатные истории';

  @override
  String get browseFreeStories => 'Просматривайте бесплатные истории';

  @override
  String get ageCategory => 'Возраст';

  @override
  String get noFreeStoriesFound => 'Бесплатные истории не найдены';

  @override
  String get tryDifferentFilters => 'Попробуйте другие фильтры';
}
