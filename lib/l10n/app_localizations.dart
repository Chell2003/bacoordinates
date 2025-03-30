import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart' as gen;
import 'package:intl/intl.dart';

class AppLocalizations extends gen.AppLocalizations {
  AppLocalizations(String locale) : super(locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  @override
  String get about => Intl.message('About', name: 'about');

  @override
  String get aboutApp => Intl.message('About App', name: 'aboutApp');

  @override
  String get activities => Intl.message('Activities', name: 'activities');

  @override
  String get activityName => Intl.message('Activity Name', name: 'activityName');

  @override
  String get activityStatus => Intl.message('Activity Status', name: 'activityStatus');

  @override
  String get add => Intl.message('Add', name: 'add');

  @override
  String get addActivity => Intl.message('Add Activity', name: 'addActivity');

  @override
  String get addComment => Intl.message('Add Comment', name: 'addComment');

  @override
  String get addPlace => Intl.message('Add Place', name: 'addPlace');

  @override
  String get addToItinerary => Intl.message('Add to Itinerary', name: 'addToItinerary');

  @override
  String get adventureActivities => Intl.message('Adventure Activities', name: 'adventureActivities');

  @override
  String get afternoonExploration => Intl.message('Afternoon Exploration', name: 'afternoonExploration');

  @override
  String get appDescription => Intl.message('App Description', name: 'appDescription');

  @override
  String get appTitle => Intl.message('App Title', name: 'appTitle');

  @override
  String get bio => Intl.message('Bio', name: 'bio');

  @override
  String get cancel => Intl.message('Cancel', name: 'cancel');

  @override
  String get changePassword => Intl.message('Change Password', name: 'changePassword');

  @override
  String get changePasswordTitle => Intl.message('Change Password', name: 'changePasswordTitle');

  @override
  String get community => Intl.message('Community', name: 'community');

  @override
  String get confirm => Intl.message('Confirm', name: 'confirm');

  @override
  String get confirmPassword => Intl.message('Confirm Password', name: 'confirmPassword');

  @override
  String get createItinerary => Intl.message('Create Itinerary', name: 'createItinerary');

  @override
  String get culturalActivities => Intl.message('Cultural Activities', name: 'culturalActivities');

  @override
  String get currentPassword => Intl.message('Current Password', name: 'currentPassword');

  @override
  String get customItinerary => Intl.message('Custom Itinerary', name: 'customItinerary');

  @override
  String get date => Intl.message('Date', name: 'date');

  @override
  String get delete => Intl.message('Delete', name: 'delete');

  @override
  String get deleteItinerary => Intl.message('Delete Itinerary', name: 'deleteItinerary');

  @override
  String get description => Intl.message('Description', name: 'description');

  @override
  String get edit => Intl.message('Edit', name: 'edit');

  @override
  String get editItinerary => Intl.message('Edit Itinerary', name: 'editItinerary');

  @override
  String get editProfile => Intl.message('Edit Profile', name: 'editProfile');

  @override
  String get email => Intl.message('Email', name: 'email');

  @override
  String get emailNotifications => Intl.message('Email Notifications', name: 'emailNotifications');

  @override
  String get eveningActivities => Intl.message('Evening Activities', name: 'eveningActivities');

  @override
  String get eveningEntertainment => Intl.message('Evening Entertainment', name: 'eveningEntertainment');

  @override
  String get explore => Intl.message('Explore', name: 'explore');

  @override
  String get generateItinerary => Intl.message('Generate Itinerary', name: 'generateItinerary');

  @override
  String get generateSampleItinerary => Intl.message('Generate Sample Itinerary', name: 'generateSampleItinerary');

  @override
  String get itinerary => Intl.message('Itinerary', name: 'itinerary');

  @override
  String get itineraryName => Intl.message('Itinerary Name', name: 'itineraryName');

  @override
  String get itineraries => Intl.message('Itineraries', name: 'itineraries');

  @override
  String get language => Intl.message('Language', name: 'language');

  @override
  String get like => Intl.message('Like', name: 'like');

  @override
  String get login => Intl.message('Login', name: 'login');

  @override
  String get logout => Intl.message('Logout', name: 'logout');

  @override
  String get morningActivities => Intl.message('Morning Activities', name: 'morningActivities');

  @override
  String get myItineraries => Intl.message('My Itineraries', name: 'myItineraries');

  @override
  String get myProfile => Intl.message('My Profile', name: 'myProfile');

  @override
  String get name => Intl.message('Name', name: 'name');

  @override
  String get newPassword => Intl.message('New Password', name: 'newPassword');

  @override
  String get noComments => Intl.message('No comments yet', name: 'noComments');

  @override
  String get noItineraries => Intl.message('No itineraries yet', name: 'noItineraries');

  @override
  String get password => Intl.message('Password', name: 'password');

  @override
  String get places => Intl.message('Places', name: 'places');

  @override
  String get post => Intl.message('Post', name: 'post');

  @override
  String get profile => Intl.message('Profile', name: 'profile');

  @override
  String get reply => Intl.message('Reply', name: 'reply');

  @override
  String get save => Intl.message('Save', name: 'save');

  @override
  String get search => Intl.message('Search', name: 'search');

  @override
  String get settings => Intl.message('Settings', name: 'settings');

  @override
  String get signUp => Intl.message('Sign Up', name: 'signUp');

  @override
  String get theme => Intl.message('Theme', name: 'theme');

  @override
  String get title => Intl.message('Title', name: 'title');

  @override
  String get translate => Intl.message('Translate', name: 'translate');

  @override
  String get translation => Intl.message('Translation', name: 'translation');

  @override
  String get update => Intl.message('Update', name: 'update');

  @override
  String get username => Intl.message('Username', name: 'username');

  @override
  String get viewItinerary => Intl.message('View Itinerary', name: 'viewItinerary');

  @override
  String get welcome => Intl.message('Welcome', name: 'welcome');
  
  @override
  String get languageSettings => Intl.message('Language Settings', name: 'languageSettings');
  
  @override
  // TODO: implement localFoodExperience
  String get localFoodExperience => throw UnimplementedError();
  
  @override
  // TODO: implement morningTour
  String get morningTour => throw UnimplementedError();
  
  @override
  // TODO: implement notifications
  String get notifications => throw UnimplementedError();
  
  @override
  // TODO: implement orSelectCommonActivities
  String get orSelectCommonActivities => throw UnimplementedError();
  
  @override
  // TODO: implement privacy
  String get privacy => throw UnimplementedError();
  
  @override
  // TODO: implement profileVisibility
  String get profileVisibility => throw UnimplementedError();
  
  @override
  // TODO: implement pushNotifications
  String get pushNotifications => throw UnimplementedError();
  
  @override
  // TODO: implement relaxation
  String get relaxation => throw UnimplementedError();
  
  @override
  // TODO: implement schedule
  String get schedule => throw UnimplementedError();
  
  @override
  // TODO: implement selectDate
  String get selectDate => throw UnimplementedError();
  
  @override
  // TODO: implement shopping
  String get shopping => throw UnimplementedError();
  
  @override
  // TODO: implement signOut
  String get signOut => throw UnimplementedError();
  
  @override
  // TODO: implement signOutConfirm
  String get signOutConfirm => throw UnimplementedError();
  
  @override
  // TODO: implement signOutTitle
  String get signOutTitle => throw UnimplementedError();
  
  @override
  // TODO: implement version
  String get version => throw UnimplementedError();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final String name = locale.countryCode == null ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);
    Intl.defaultLocale = localeName;
    return AppLocalizations(localeName);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 