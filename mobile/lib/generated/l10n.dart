// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Fix your home issues quickly & safely`
  String get getStartedSubtitle {
    return Intl.message(
      'Fix your home issues quickly & safely',
      name: 'getStartedSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Got a problem at home?\nRequest a trusted technician in minutes with ease.\n\n✓ Trusted technician selections\n✓ Step-by-step order tracking\n✓ Simple and easy-to-use experience`
  String get getStartedDescription {
    return Intl.message(
      'Got a problem at home?\nRequest a trusted technician in minutes with ease.\n\n✓ Trusted technician selections\n✓ Step-by-step order tracking\n✓ Simple and easy-to-use experience',
      name: 'getStartedDescription',
      desc: '',
      args: [],
    );
  }

  /// `Get Started`
  String get getStartedButton {
    return Intl.message(
      'Get Started',
      name: 'getStartedButton',
      desc: '',
      args: [],
    );
  }

  /// `Don't worry, your data is 100% safe with us`
  String get getStartedFooter {
    return Intl.message(
      'Don\'t worry, your data is 100% safe with us',
      name: 'getStartedFooter',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message(
      'Dark Mode',
      name: 'darkMode',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message(
      'Language',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `العربية`
  String get arabic {
    return Intl.message(
      'العربية',
      name: 'arabic',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get english {
    return Intl.message(
      'English',
      name: 'english',
      desc: '',
      args: [],
    );
  }

  /// `Skip`
  String get skip {
    return Intl.message(
      'Skip',
      name: 'skip',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `How It Works`
  String get howItWorks {
    return Intl.message(
      'How It Works',
      name: 'howItWorks',
      desc: '',
      args: [],
    );
  }

  /// `Easy interface\nConnect & request a technician quickly`
  String get firstScreenDesc {
    return Intl.message(
      'Easy interface\nConnect & request a technician quickly',
      name: 'firstScreenDesc',
      desc: '',
      args: [],
    );
  }

  /// `Trusted Services`
  String get trustedServices {
    return Intl.message(
      'Trusted Services',
      name: 'trustedServices',
      desc: '',
      args: [],
    );
  }

  /// `Talk directly with technicians\nSmooth and fast experience`
  String get secondScreenDesc {
    return Intl.message(
      'Talk directly with technicians\nSmooth and fast experience',
      name: 'secondScreenDesc',
      desc: '',
      args: [],
    );
  }

  /// `Easy Requests`
  String get easyRequests {
    return Intl.message(
      'Easy Requests',
      name: 'easyRequests',
      desc: '',
      args: [],
    );
  }

  /// `Send issues & track responses\nFast and smooth experience`
  String get thirdScreenDesc {
    return Intl.message(
      'Send issues & track responses\nFast and smooth experience',
      name: 'thirdScreenDesc',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get welcome {
    return Intl.message(
      'Welcome',
      name: 'welcome',
      desc: '',
      args: [],
    );
  }

  /// `Start fixing any home issue quickly and easily!`
  String get chooseAccountSubtitle {
    return Intl.message(
      'Start fixing any home issue quickly and easily!',
      name: 'chooseAccountSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Customer`
  String get customer {
    return Intl.message(
      'Customer',
      name: 'customer',
      desc: '',
      args: [],
    );
  }

  /// `Technician`
  String get technician {
    return Intl.message(
      'Technician',
      name: 'technician',
      desc: '',
      args: [],
    );
  }

  /// `Join now and enjoy an easier and faster way to fix all your home issues!`
  String get chooseAccountFooter {
    return Intl.message(
      'Join now and enjoy an easier and faster way to fix all your home issues!',
      name: 'chooseAccountFooter',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your email`
  String get pleaseEnterYourEmail {
    return Intl.message(
      'Please enter your email',
      name: 'pleaseEnterYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email`
  String get invalidEmail {
    return Intl.message(
      'Invalid email',
      name: 'invalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your password`
  String get pleaseEnterYourPassword {
    return Intl.message(
      'Please enter your password',
      name: 'pleaseEnterYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password is too short`
  String get passwordTooShort {
    return Intl.message(
      'Password is too short',
      name: 'passwordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get dontHaveAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'dontHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Sign up`
  String get signUp {
    return Intl.message(
      'Sign up',
      name: 'signUp',
      desc: '',
      args: [],
    );
  }

  /// `Full Name`
  String get fullName {
    return Intl.message(
      'Full Name',
      name: 'fullName',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your name`
  String get pleaseEnterYourName {
    return Intl.message(
      'Please enter your name',
      name: 'pleaseEnterYourName',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your phone number`
  String get pleaseEnterYourPhoneNumber {
    return Intl.message(
      'Please enter your phone number',
      name: 'pleaseEnterYourPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Invalid phone number`
  String get invalidPhoneNumber {
    return Intl.message(
      'Invalid phone number',
      name: 'invalidPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message(
      'Register',
      name: 'register',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get alreadyHaveAccount {
    return Intl.message(
      'Already have an account?',
      name: 'alreadyHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get category {
    return Intl.message(
      'Category',
      name: 'category',
      desc: '',
      args: [],
    );
  }

  /// `View All`
  String get viewAll {
    return Intl.message(
      'View All',
      name: 'viewAll',
      desc: '',
      args: [],
    );
  }

  /// `Hot Deals`
  String get hotDeals {
    return Intl.message(
      'Hot Deals',
      name: 'hotDeals',
      desc: '',
      args: [],
    );
  }

  /// `My Services`
  String get myServices {
    return Intl.message(
      'My Services',
      name: 'myServices',
      desc: '',
      args: [],
    );
  }

  /// `Electric`
  String get electric {
    return Intl.message(
      'Electric',
      name: 'electric',
      desc: '',
      args: [],
    );
  }

  /// `Electric Fix`
  String get electricFix {
    return Intl.message(
      'Electric Fix',
      name: 'electricFix',
      desc: '',
      args: [],
    );
  }

  /// `Fix all your electric issues quickly and professionally.`
  String get electricFixDescription {
    return Intl.message(
      'Fix all your electric issues quickly and professionally.',
      name: 'electricFixDescription',
      desc: '',
      args: [],
    );
  }

  /// `Plumbing`
  String get plumbing {
    return Intl.message(
      'Plumbing',
      name: 'plumbing',
      desc: '',
      args: [],
    );
  }

  /// `Plumbing services with guaranteed quality.`
  String get plumbingDescription {
    return Intl.message(
      'Plumbing services with guaranteed quality.',
      name: 'plumbingDescription',
      desc: '',
      args: [],
    );
  }

  /// `Cleaning`
  String get cleaning {
    return Intl.message(
      'Cleaning',
      name: 'cleaning',
      desc: '',
      args: [],
    );
  }

  /// `Home and office cleaning services at your door.`
  String get cleaningDescription {
    return Intl.message(
      'Home and office cleaning services at your door.',
      name: 'cleaningDescription',
      desc: '',
      args: [],
    );
  }

  /// `Great service!`
  String get greatService {
    return Intl.message(
      'Great service!',
      name: 'greatService',
      desc: '',
      args: [],
    );
  }

  /// `Very professional!`
  String get veryProfessional {
    return Intl.message(
      'Very professional!',
      name: 'veryProfessional',
      desc: '',
      args: [],
    );
  }

  /// `Fast and reliable!`
  String get fastAndReliable {
    return Intl.message(
      'Fast and reliable!',
      name: 'fastAndReliable',
      desc: '',
      args: [],
    );
  }

  /// `Highly recommended!`
  String get highlyRecommended {
    return Intl.message(
      'Highly recommended!',
      name: 'highlyRecommended',
      desc: '',
      args: [],
    );
  }

  /// `Very thorough!`
  String get veryThorough {
    return Intl.message(
      'Very thorough!',
      name: 'veryThorough',
      desc: '',
      args: [],
    );
  }

  /// `Nice and friendly staff!`
  String get niceAndFriendlyStaff {
    return Intl.message(
      'Nice and friendly staff!',
      name: 'niceAndFriendlyStaff',
      desc: '',
      args: [],
    );
  }

  /// `123 Main Street, Cairo`
  String get addressMainStreetCairo {
    return Intl.message(
      '123 Main Street, Cairo',
      name: 'addressMainStreetCairo',
      desc: '',
      args: [],
    );
  }

  /// `45 Nile Street, Cairo`
  String get addressNileStreetCairo {
    return Intl.message(
      '45 Nile Street, Cairo',
      name: 'addressNileStreetCairo',
      desc: '',
      args: [],
    );
  }

  /// `67 Garden St, Giza`
  String get addressGardenStGiza {
    return Intl.message(
      '67 Garden St, Giza',
      name: 'addressGardenStGiza',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get location {
    return Intl.message(
      'Location',
      name: 'location',
      desc: '',
      args: [],
    );
  }

  /// `Dhaka, Bangladesh`
  String get currentLocation {
    return Intl.message(
      'Dhaka, Bangladesh',
      name: 'currentLocation',
      desc: '',
      args: [],
    );
  }

  /// `Service Provider`
  String get serviceProvider {
    return Intl.message(
      'Service Provider',
      name: 'serviceProvider',
      desc: '',
      args: [],
    );
  }

  /// `Book`
  String get book {
    return Intl.message(
      'Book',
      name: 'book',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Find your favorite items`
  String get searchHint {
    return Intl.message(
      'Find your favorite items',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message(
      'Home',
      name: 'home',
      desc: '',
      args: [],
    );
  }

  /// `Favorites`
  String get favorites {
    return Intl.message(
      'Favorites',
      name: 'favorites',
      desc: '',
      args: [],
    );
  }

  /// `Job History`
  String get jobHistory {
    return Intl.message(
      'Job History',
      name: 'jobHistory',
      desc: '',
      args: [],
    );
  }

  /// `Requests`
  String get requests {
    return Intl.message(
      'Requests',
      name: 'requests',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get account {
    return Intl.message(
      'Account',
      name: 'account',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get details {
    return Intl.message(
      'Details',
      name: 'details',
      desc: '',
      args: [],
    );
  }

  /// `Reviews`
  String get reviews {
    return Intl.message(
      'Reviews',
      name: 'reviews',
      desc: '',
      args: [],
    );
  }

  /// `Info`
  String get info {
    return Intl.message(
      'Info',
      name: 'info',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message(
      'Description',
      name: 'description',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message(
      'Address',
      name: 'address',
      desc: '',
      args: [],
    );
  }

  /// `View On Map`
  String get viewOnMap {
    return Intl.message(
      'View On Map',
      name: 'viewOnMap',
      desc: '',
      args: [],
    );
  }

  /// `Book Now`
  String get bookNow {
    return Intl.message(
      'Book Now',
      name: 'bookNow',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `The service is fantastic! Very clean, professional, and fast. Highly recommended!`
  String get reviewExample {
    return Intl.message(
      'The service is fantastic! Very clean, professional, and fast. Highly recommended!',
      name: 'reviewExample',
      desc: '',
      args: [],
    );
  }

  /// `Add Service`
  String get addService {
    return Intl.message(
      'Add Service',
      name: 'addService',
      desc: '',
      args: [],
    );
  }

  /// `Add a new service you provide`
  String get addServiceDesc {
    return Intl.message(
      'Add a new service you provide',
      name: 'addServiceDesc',
      desc: '',
      args: [],
    );
  }

  /// `Addresses`
  String get addresses {
    return Intl.message(
      'Addresses',
      name: 'addresses',
      desc: '',
      args: [],
    );
  }

  /// `Manage your saved addresses`
  String get addressesDesc {
    return Intl.message(
      'Manage your saved addresses',
      name: 'addressesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Payment Methods`
  String get paymentMethods {
    return Intl.message(
      'Payment Methods',
      name: 'paymentMethods',
      desc: '',
      args: [],
    );
  }

  /// `Your cards & payment options`
  String get paymentMethodsDesc {
    return Intl.message(
      'Your cards & payment options',
      name: 'paymentMethodsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Manage app preferences`
  String get settingsDesc {
    return Intl.message(
      'Manage app preferences',
      name: 'settingsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message(
      'Logout',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to logout?`
  String get logoutConfirm {
    return Intl.message(
      'Are you sure you want to logout?',
      name: 'logoutConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Ratings`
  String get ratings {
    return Intl.message(
      'Ratings',
      name: 'ratings',
      desc: '',
      args: [],
    );
  }

  /// `Service Title`
  String get serviceTitle {
    return Intl.message(
      'Service Title',
      name: 'serviceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Service Description`
  String get serviceDescription {
    return Intl.message(
      'Service Description',
      name: 'serviceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Service Added`
  String get serviceAdded {
    return Intl.message(
      'Service Added',
      name: 'serviceAdded',
      desc: '',
      args: [],
    );
  }

  /// `Your service "{title}" has been successfully added.`
  String serviceAddedMessage(Object title) {
    return Intl.message(
      'Your service "$title" has been successfully added.',
      name: 'serviceAddedMessage',
      desc: '',
      args: [title],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `My Requests`
  String get myRequests {
    return Intl.message(
      'My Requests',
      name: 'myRequests',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get pending {
    return Intl.message(
      'Pending',
      name: 'pending',
      desc: '',
      args: [],
    );
  }

  /// `Confirmed`
  String get confirmed {
    return Intl.message(
      'Confirmed',
      name: 'confirmed',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get completed {
    return Intl.message(
      'Completed',
      name: 'completed',
      desc: '',
      args: [],
    );
  }

  /// `Canceled`
  String get canceled {
    return Intl.message(
      'Canceled',
      name: 'canceled',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get date {
    return Intl.message(
      'Date',
      name: 'date',
      desc: '',
      args: [],
    );
  }

  /// `Cancel Request`
  String get cancelRequest {
    return Intl.message(
      'Cancel Request',
      name: 'cancelRequest',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to cancel this request?`
  String get cancelRequestConfirm {
    return Intl.message(
      'Are you sure you want to cancel this request?',
      name: 'cancelRequestConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message(
      'Yes',
      name: 'yes',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Fixing power outage in living room`
  String get electricFixRequestDesc {
    return Intl.message(
      'Fixing power outage in living room',
      name: 'electricFixRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `Plumbing Service`
  String get plumbingService {
    return Intl.message(
      'Plumbing Service',
      name: 'plumbingService',
      desc: '',
      args: [],
    );
  }

  /// `Kitchen sink leaking`
  String get plumbingServiceRequestDesc {
    return Intl.message(
      'Kitchen sink leaking',
      name: 'plumbingServiceRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `Cleaning Service`
  String get cleaningService {
    return Intl.message(
      'Cleaning Service',
      name: 'cleaningService',
      desc: '',
      args: [],
    );
  }

  /// `Full apartment cleaning`
  String get cleaningServiceRequestDesc {
    return Intl.message(
      'Full apartment cleaning',
      name: 'cleaningServiceRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `AC Maintenance`
  String get acMaintenance {
    return Intl.message(
      'AC Maintenance',
      name: 'acMaintenance',
      desc: '',
      args: [],
    );
  }

  /// `AC not cooling properly`
  String get acMaintenanceRequestDesc {
    return Intl.message(
      'AC not cooling properly',
      name: 'acMaintenanceRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `Checkout`
  String get checkout {
    return Intl.message(
      'Checkout',
      name: 'checkout',
      desc: '',
      args: [],
    );
  }

  /// `Delivery Address`
  String get deliveryAddress {
    return Intl.message(
      'Delivery Address',
      name: 'deliveryAddress',
      desc: '',
      args: [],
    );
  }

  /// `Change`
  String get change {
    return Intl.message(
      'Change',
      name: 'change',
      desc: '',
      args: [],
    );
  }

  /// `Payment Method`
  String get paymentMethod {
    return Intl.message(
      'Payment Method',
      name: 'paymentMethod',
      desc: '',
      args: [],
    );
  }

  /// `Card`
  String get card {
    return Intl.message(
      'Card',
      name: 'card',
      desc: '',
      args: [],
    );
  }

  /// `Cash`
  String get cash {
    return Intl.message(
      'Cash',
      name: 'cash',
      desc: '',
      args: [],
    );
  }

  /// `Pay`
  String get applePay {
    return Intl.message(
      'Pay',
      name: 'applePay',
      desc: '',
      args: [],
    );
  }

  /// `Enter problem description`
  String get enterProblem {
    return Intl.message(
      'Enter problem description',
      name: 'enterProblem',
      desc: '',
      args: [],
    );
  }

  /// `Booking Fee`
  String get bookingFee {
    return Intl.message(
      'Booking Fee',
      name: 'bookingFee',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get price {
    return Intl.message(
      'Price',
      name: 'price',
      desc: '',
      args: [],
    );
  }

  /// `Note: If you cancel the service, your booking fee will not be refunded.`
  String get note {
    return Intl.message(
      'Note: If you cancel the service, your booking fee will not be refunded.',
      name: 'note',
      desc: '',
      args: [],
    );
  }

  /// `Promo Code`
  String get promoCode {
    return Intl.message(
      'Promo Code',
      name: 'promoCode',
      desc: '',
      args: [],
    );
  }

  /// `Enter Promo Code`
  String get enterPromo {
    return Intl.message(
      'Enter Promo Code',
      name: 'enterPromo',
      desc: '',
      args: [],
    );
  }

  /// `Apply`
  String get apply {
    return Intl.message(
      'Apply',
      name: 'apply',
      desc: '',
      args: [],
    );
  }

  /// `Place Order`
  String get placeOrder {
    return Intl.message(
      'Place Order',
      name: 'placeOrder',
      desc: '',
      args: [],
    );
  }

  /// `Order Placed!`
  String get orderPlaced {
    return Intl.message(
      'Order Placed!',
      name: 'orderPlaced',
      desc: '',
      args: [],
    );
  }

  /// `Your order has been successfully placed.`
  String get orderSuccess {
    return Intl.message(
      'Your order has been successfully placed.',
      name: 'orderSuccess',
      desc: '',
      args: [],
    );
  }

  /// `My Cards`
  String get myCards {
    return Intl.message(
      'My Cards',
      name: 'myCards',
      desc: '',
      args: [],
    );
  }

  /// `Cards`
  String get cards {
    return Intl.message(
      'Cards',
      name: 'cards',
      desc: '',
      args: [],
    );
  }

  /// `Add New Card`
  String get addNewCard {
    return Intl.message(
      'Add New Card',
      name: 'addNewCard',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get defaultLabel {
    return Intl.message(
      'Default',
      name: 'defaultLabel',
      desc: '',
      args: [],
    );
  }

  /// `Add Debit or Credit Card`
  String get addDebitOrCreditCard {
    return Intl.message(
      'Add Debit or Credit Card',
      name: 'addDebitOrCreditCard',
      desc: '',
      args: [],
    );
  }

  /// `Card Number`
  String get cardNumber {
    return Intl.message(
      'Card Number',
      name: 'cardNumber',
      desc: '',
      args: [],
    );
  }

  /// `Expiry Date`
  String get expiryDate {
    return Intl.message(
      'Expiry Date',
      name: 'expiryDate',
      desc: '',
      args: [],
    );
  }

  /// `CVV`
  String get cvv {
    return Intl.message(
      'CVV',
      name: 'cvv',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your username`
  String get pleaseEnterYourUsername {
    return Intl.message(
      'Please enter your username',
      name: 'pleaseEnterYourUsername',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your address`
  String get pleaseEnterYourAddress {
    return Intl.message(
      'Please enter your address',
      name: 'pleaseEnterYourAddress',
      desc: '',
      args: [],
    );
  }

}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
