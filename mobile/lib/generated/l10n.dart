// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
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
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  String get getStartedSubtitle => Intl.message('Fix your home issues quickly & safely', name: 'getStartedSubtitle');
  String get getStartedDescription => Intl.message('Got a problem at home?\nRequest a trusted technician in minutes with ease.\n\n✓ Trusted technician selections\n✓ Step-by-step order tracking\n✓ Simple and easy-to-use experience', name: 'getStartedDescription');
  String get getStartedButton => Intl.message('Get Started', name: 'getStartedButton');
  String get getStartedFooter => Intl.message('Don\'t worry, your data is 100% safe with us', name: 'getStartedFooter');
  String get settings => Intl.message('Settings', name: 'settings');
  String get darkMode => Intl.message('Dark Mode', name: 'darkMode');
  String get language => Intl.message('Language', name: 'language');
  String get arabic => Intl.message('العربية', name: 'arabic');
  String get english => Intl.message('English', name: 'english');
  String hello(Object name) => Intl.message('Hello, $name!', name: 'hello', args: [name]);
  String get skip => Intl.message('Skip', name: 'skip');
  String get next => Intl.message('Next', name: 'next');
  String get login => Intl.message('Login', name: 'login');
  String get howItWorks => Intl.message('How It Works', name: 'howItWorks');
  String get firstScreenDesc => Intl.message('Easy interface\nConnect & request a technician quickly', name: 'firstScreenDesc');
  String get trustedServices => Intl.message('Trusted Services', name: 'trustedServices');
  String get secondScreenDesc => Intl.message('Talk directly with technicians\nSmooth and fast experience', name: 'secondScreenDesc');
  String get easyRequests => Intl.message('Easy Requests', name: 'easyRequests');
  String get thirdScreenDesc => Intl.message('Send issues & track responses\nFast and smooth experience', name: 'thirdScreenDesc');
  String get welcome => Intl.message('Welcome', name: 'welcome');
  String get chooseAccountSubtitle => Intl.message('Start fixing any home issue quickly and easily!', name: 'chooseAccountSubtitle');
  String get customer => Intl.message('Customer', name: 'customer');
  String get technician => Intl.message('Technician', name: 'technician');
  String get chooseAccountFooter => Intl.message('Join now and enjoy an easier and faster way to fix all your home issues!', name: 'chooseAccountFooter');
  String get email => Intl.message('Email', name: 'email');
  String get password => Intl.message('Password', name: 'password');
  String get pleaseEnterYourEmail => Intl.message('Please enter your email', name: 'pleaseEnterYourEmail');
  String get invalidEmail => Intl.message('Invalid email', name: 'invalidEmail');
  String get pleaseEnterYourPassword => Intl.message('Please enter your password', name: 'pleaseEnterYourPassword');
  String get passwordTooShort => Intl.message('Password is too short', name: 'passwordTooShort');
  String get dontHaveAccount => Intl.message('Don\'t have an account?', name: 'dontHaveAccount');
  String get signUp => Intl.message('Sign up', name: 'signUp');
  String get fullName => Intl.message('Full Name', name: 'fullName');
  String get pleaseEnterYourName => Intl.message('Please enter your name', name: 'pleaseEnterYourName');
  String get phoneNumber => Intl.message('Phone Number', name: 'phoneNumber');
  String get pleaseEnterYourPhoneNumber => Intl.message('Please enter your phone number', name: 'pleaseEnterYourPhoneNumber');
  String get invalidPhoneNumber => Intl.message('Invalid phone number', name: 'invalidPhoneNumber');
  String get register => Intl.message('Register', name: 'register');
  String get alreadyHaveAccount => Intl.message('Already have an account?', name: 'alreadyHaveAccount');
  String get category => Intl.message('Category', name: 'category');
  String get viewAll => Intl.message('View All', name: 'viewAll');
  String get hotDeals => Intl.message('Hot Deals', name: 'hotDeals');
  String get myServices => Intl.message('My Services', name: 'myServices');
  String get electric => Intl.message('Electric', name: 'electric');
  String get electricFix => Intl.message('Electric Fix', name: 'electricFix');
  String get electricFixDescription => Intl.message('Fix all your electric issues quickly and professionally.', name: 'electricFixDescription');
  String get plumbing => Intl.message('Plumbing', name: 'plumbing');
  String get plumbingDescription => Intl.message('Plumbing services with guaranteed quality.', name: 'plumbingDescription');
  String get cleaning => Intl.message('Cleaning', name: 'cleaning');
  String get cleaningDescription => Intl.message('Home and office cleaning services at your door.', name: 'cleaningDescription');
  String get greatService => Intl.message('Great service!', name: 'greatService');
  String get veryProfessional => Intl.message('Very professional!', name: 'veryProfessional');
  String get fastAndReliable => Intl.message('Fast and reliable!', name: 'fastAndReliable');
  String get highlyRecommended => Intl.message('Highly recommended!', name: 'highlyRecommended');
  String get veryThorough => Intl.message('Very thorough!', name: 'veryThorough');
  String get niceAndFriendlyStaff => Intl.message('Nice and friendly staff!', name: 'niceAndFriendlyStaff');
  String get addressMainStreetCairo => Intl.message('123 Main Street, Cairo', name: 'addressMainStreetCairo');
  String get addressNileStreetCairo => Intl.message('45 Nile Street, Cairo', name: 'addressNileStreetCairo');
  String get addressGardenStGiza => Intl.message('67 Garden St, Giza', name: 'addressGardenStGiza');
  String get location => Intl.message('Location', name: 'location');
  String get currentLocation => Intl.message('Dhaka, Bangladesh', name: 'currentLocation');
  String get serviceProvider => Intl.message('Service Provider', name: 'serviceProvider');
  String get book => Intl.message('Book', name: 'book');
  String get edit => Intl.message('Edit', name: 'edit');
  String get searchHint => Intl.message('Find your favorite items', name: 'searchHint');
  String get home => Intl.message('Home', name: 'home');
  String get favorites => Intl.message('Favorites', name: 'favorites');
  String get jobHistory => Intl.message('Job History', name: 'jobHistory');
  String get requests => Intl.message('Requests', name: 'requests');
  String get account => Intl.message('Account', name: 'account');
  String get details => Intl.message('Details', name: 'details');
  String get reviews => Intl.message('Reviews', name: 'reviews');
  String get info => Intl.message('Info', name: 'info');
  String get description => Intl.message('Description', name: 'description');
  String get address => Intl.message('Address', name: 'address');
  String get viewOnMap => Intl.message('View On Map', name: 'viewOnMap');
  String get bookNow => Intl.message('Book Now', name: 'bookNow');
  String get delete => Intl.message('Delete', name: 'delete');
  String get reviewExample => Intl.message('The service is fantastic! Very clean, professional, and fast. Highly recommended!', name: 'reviewExample');
  String get addService => Intl.message('Add Service', name: 'addService');
  String get addServiceDesc => Intl.message('Add a new service you provide', name: 'addServiceDesc');
  String get addresses => Intl.message('Addresses', name: 'addresses');
  String get addressesDesc => Intl.message('Manage your saved addresses', name: 'addressesDesc');
  String get paymentMethods => Intl.message('Payment Methods', name: 'paymentMethods');
  String get paymentMethodsDesc => Intl.message('Your cards & payment options', name: 'paymentMethodsDesc');
  String get settingsDesc => Intl.message('Manage app preferences', name: 'settingsDesc');
  String get logout => Intl.message('Logout', name: 'logout');
  String get logoutConfirm => Intl.message('Are you sure you want to logout?', name: 'logoutConfirm');
  String get cancel => Intl.message('Cancel', name: 'cancel');
  String get ratings => Intl.message('Ratings', name: 'ratings');
  String get serviceTitle => Intl.message('Service Title', name: 'serviceTitle');
  String get serviceDescription => Intl.message('Service Description', name: 'serviceDescription');
  String get serviceAdded => Intl.message('Service Added', name: 'serviceAdded');
  String serviceAddedMessage(Object title) => Intl.message('Your service "$title" has been successfully added.', name: 'serviceAddedMessage', args: [title]);
  String get ok => Intl.message('OK', name: 'ok');
  String get myRequests => Intl.message('My Requests', name: 'myRequests');
  String get pending => Intl.message('Pending', name: 'pending');
  String get confirmed => Intl.message('Confirmed', name: 'confirmed');
  String get completed => Intl.message('Completed', name: 'completed');
  String get canceled => Intl.message('Canceled', name: 'canceled');
  String get date => Intl.message('Date', name: 'date');
  String get cancelRequest => Intl.message('Cancel Request', name: 'cancelRequest');
  String get cancelRequestConfirm => Intl.message('Are you sure you want to cancel this request?', name: 'cancelRequestConfirm');
  String get yes => Intl.message('Yes', name: 'yes');
  String get no => Intl.message('No', name: 'no');
  String get electricFixRequestDesc => Intl.message('Fixing power outage in living room', name: 'electricFixRequestDesc');
  String get plumbingService => Intl.message('Plumbing Service', name: 'plumbingService');
  String get plumbingServiceRequestDesc => Intl.message('Kitchen sink leaking', name: 'plumbingServiceRequestDesc');
  String get cleaningService => Intl.message('Cleaning Service', name: 'cleaningService');
  String get cleaningServiceRequestDesc => Intl.message('Full apartment cleaning', name: 'cleaningServiceRequestDesc');
  String get acMaintenance => Intl.message('AC Maintenance', name: 'acMaintenance');
  String get acMaintenanceRequestDesc => Intl.message('AC not cooling properly', name: 'acMaintenanceRequestDesc');
  String get checkout => Intl.message('Checkout', name: 'checkout');
  String get deliveryAddress => Intl.message('Delivery Address', name: 'deliveryAddress');
  String get change => Intl.message('Change', name: 'change');
  String get paymentMethod => Intl.message('Payment Method', name: 'paymentMethod');
  String get card => Intl.message('Card', name: 'card');
  String get cash => Intl.message('Cash', name: 'cash');
  String get applePay => Intl.message('Pay', name: 'applePay');
  String get enterProblem => Intl.message('Enter problem description', name: 'enterProblem');
  String get bookingFee => Intl.message('Booking Fee', name: 'bookingFee');
  String get price => Intl.message('Price', name: 'price');
  String get note => Intl.message('Note: If you cancel the service, your booking fee will not be refunded.', name: 'note');
  String get promoCode => Intl.message('Promo Code', name: 'promoCode');
  String get enterPromo => Intl.message('Enter Promo Code', name: 'enterPromo');
  String get apply => Intl.message('Apply', name: 'apply');
  String get placeOrder => Intl.message('Place Order', name: 'placeOrder');
  String get orderPlaced => Intl.message('Order Placed!', name: 'orderPlaced');
  String get orderSuccess => Intl.message('Your order has been successfully placed.', name: 'orderSuccess');
  String get myCards => Intl.message('My Cards', name: 'myCards');
  String get cards => Intl.message('Cards', name: 'cards');
  String get addNewCard => Intl.message('Add New Card', name: 'addNewCard');
  String get defaultLabel => Intl.message('Default', name: 'defaultLabel');
  String get addDebitOrCreditCard => Intl.message('Add Debit or Credit Card', name: 'addDebitOrCreditCard');
  String get cardNumber => Intl.message('Card Number', name: 'cardNumber');
  String get expiryDate => Intl.message('Expiry Date', name: 'expiryDate');
  String get cvv => Intl.message('CVV', name: 'cvv');
  String get addressesPageTitle => Intl.message('My Addresses', name: 'addressesPageTitle');
  String get addNewAddress => Intl.message('Add New Address', name: 'addNewAddress');
  String get addressNickname => Intl.message('Address Nickname', name: 'addressNickname');
  String get addressDetails => Intl.message('Address Details', name: 'addressDetails');
  String get makeDefault => Intl.message('Make this as a default', name: 'makeDefault');
  String get requestDetails => Intl.message('Request Details', name: 'requestDetails');
  String get statusLabel => Intl.message('Status: ', name: 'statusLabel');
  String get accept => Intl.message('Accept', name: 'accept');

  // New keys
  String get inProgress => Intl.message('In Progress', name: 'inProgress');
  String get rejected => Intl.message('Rejected', name: 'rejected');
  String get noFavorites => Intl.message('No favorites yet', name: 'noFavorites');
  String get noRequests => Intl.message('No requests', name: 'noRequests');
  String get noPendingRequests => Intl.message('No pending requests', name: 'noPendingRequests');
  String get experience => Intl.message('Experience', name: 'experience');
  String get yearsOfExperience => Intl.message('Years of Experience', name: 'yearsOfExperience');
  String get years => Intl.message('years', name: 'years');
  String get jobs => Intl.message('jobs', name: 'jobs');
  String get noJobHistory => Intl.message('No job history', name: 'noJobHistory');
  String get specializesIn => Intl.message('Specializes in', name: 'specializesIn');
  String get selectCategory => Intl.message('Select a category', name: 'selectCategory');
  String get availableForWork => Intl.message('Available for Work', name: 'availableForWork');
  String get createProfile => Intl.message('Create Profile', name: 'createProfile');
  String get profileCreated => Intl.message('Profile Created', name: 'profileCreated');
  String get profileCreatedMessage => Intl.message('Your worker profile has been created successfully.', name: 'profileCreatedMessage');
  String get creatingProfile => Intl.message('Creating profile...', name: 'creatingProfile');
  String get descriptionHint => Intl.message('Tell us about your skills and experience', name: 'descriptionHint');
  String get noReviews => Intl.message('No reviews yet', name: 'noReviews');
  String get anonymous => Intl.message('Anonymous', name: 'anonymous');
  String get useAccountPhone => Intl.message('Use account phone', name: 'useAccountPhone');
  String get useSavedAddress => Intl.message('Use saved address', name: 'useSavedAddress');
  String get orderDetails => Intl.message('Order Details', name: 'orderDetails');
  String get contactInfo => Intl.message('Contact Information', name: 'contactInfo');
  String get phoneForOrder => Intl.message('Phone for this order', name: 'phoneForOrder');
  String get addressForOrder => Intl.message('Address for this order', name: 'addressForOrder');
  String get rateService => Intl.message('Rate Service', name: 'rateService');
  String get submitRating => Intl.message('Submit Rating', name: 'submitRating');
  String get submitting => Intl.message('Submitting...', name: 'submitting');
  String get ratingSubmitted => Intl.message('Rating submitted successfully!', name: 'ratingSubmitted');
  String get reviewHint => Intl.message('Share your experience (optional)', name: 'reviewHint');
  String get rateOrder => Intl.message('Rate', name: 'rateOrder');
  String get errorOccurred => Intl.message('An error occurred. Please try again.', name: 'errorOccurred');
  String get cancelledByYou => Intl.message('Cancelled by you', name: 'cancelledByYou');
  String get cancelledByCustomer => Intl.message('Cancelled by the customer', name: 'cancelledByCustomer');
  String get rejectedByWorker => Intl.message('Rejected by the worker', name: 'rejectedByWorker');
  String get rejectedByYou => Intl.message('Rejected by you', name: 'rejectedByYou');
  String get waitingConfirmation => Intl.message('Waiting Confirmation', name: 'waitingConfirmation');
  String get markAsFinished => Intl.message('Mark as Finished', name: 'markAsFinished');
  String get confirmCompletion => Intl.message('Confirm Completion', name: 'confirmCompletion');
  String get workerMarkedFinished => Intl.message('The worker marked this job as finished', name: 'workerMarkedFinished');
  String get notifications => Intl.message('Notifications', name: 'notifications');
  String get markAllRead => Intl.message('Mark all as read', name: 'markAllRead');
  String get noNotifications => Intl.message('No notifications yet', name: 'noNotifications');
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
