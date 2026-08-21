import 'app_strings.dart';

/// English UI strings.
class StringsEn implements AppStrings {
  const StringsEn();

  @override
  AppLanguage get language => AppLanguage.en;

  @override
  String get menuTitle => 'Menu';
  @override
  String menuTitleForTable(int table) => 'Menu · Table $table';
  @override
  String get becomeLoyal => 'Become a loyal customer';
  @override
  String get loyalCustomer => 'Loyal customer';
  @override
  String get loyalIntro => 'Faster ordering, history and offers';
  @override
  String get loyalEnroll => 'Enrol';
  @override
  String get leaveLoyalty => 'Leave the programme';
  @override
  String get signInWithPhone => 'Sign in with your phone';
  @override
  String get signOutAccount => 'Sign out';
  @override
  String get signInTitle => 'Sign in';
  @override
  String get phoneLabel => 'Phone number';
  @override
  String get sendCode => 'Send code';
  @override
  String get sendCodeFailed => 'Could not send the code, try again';
  @override
  String demoCodeIs(String code) => 'Demo: the code is $code';
  @override
  String get consentLoyalty => 'I agree to collect loyalty points';
  @override
  String get consentMarketing => 'Send me offers by phone (optional)';
  @override
  String get otpWrong => 'Wrong code';
  @override
  String get chooseTablePrompt => 'Tell us your table so you can order';
  @override
  String get chooseTable => 'Choose table';
  @override
  String get scanTable => 'Scan the table';
  @override
  String get unknownVenueTitle => 'Venue not found';
  @override
  String get unknownVenueBody =>
      'This link does not match a known venue. Please scan the QR code on your '
      'table again, or ask the staff for help.';
  @override
  String get account => 'My account';
  @override
  String get orderHistory => 'Order history';
  @override
  String get noHistoryYet => 'No orders yet';
  @override
  String greeting(String name) => 'Hi, $name 👋';
  @override
  String get welcomeLoyal => 'Welcome to the loyalty program!';
  @override
  String get rewards => 'Rewards';
  @override
  String get pointsLabel => 'points';
  @override
  String points(int value) => '$value points';
  @override
  String pointsToNext(int value, String reward) =>
      '$value more points for "$reward"';
  @override
  String get allRewardsUnlocked => 'You have unlocked every reward';
  @override
  String get rewardUnlocked => 'Unlocked';
  @override
  String get redeem => 'Redeem';
  @override
  String get redeemCodeTitle => 'Show this code to the staff';
  @override
  String get redeemFailed => 'Could not redeem the reward';
  @override
  String get gotIt => 'Got it';
  @override
  String get myRedemptions => 'My rewards';
  @override
  String get redemptionPending => 'To use';
  @override
  String get redemptionUsed => 'Used';
  @override
  String get rewardsToValidate => 'Rewards to validate';
  @override
  String get validate => 'Validate';
  @override
  String get callWaiter => 'Call the waiter';
  @override
  String get bringBill => 'Bring the bill';
  @override
  String get cart => 'Cart';
  @override
  String get searchHint => 'Search the menu';
  @override
  String get onlyAvailableNow => 'Available now';
  @override
  String get nothingFound => 'Nothing found';
  @override
  String get couldNotLoadMenu => 'Could not load the menu.';
  @override
  String get waiterNotified => 'The waiter has been notified.';
  @override
  String get billOnTheWay => 'The bill is on the way.';
  @override
  String get unavailableNow => 'unavailable now';
  @override
  String availableAt(String hours) => 'available $hours';
  @override
  String get addToCart => 'Add to cart';
  @override
  String get quantity => 'Quantity';
  @override
  String addedToCart(String name) => '$name added';
  @override
  String cartFab(int count, String total) => 'Cart ($count) · $total';

  @override
  String get orderTitle => 'Order';
  @override
  String get cartEmpty => 'Your cart is empty';
  @override
  String get seeMenu => 'See the menu';
  @override
  String get total => 'Total';
  @override
  String youSaved(String amount) => 'You saved $amount';
  @override
  String get nameRequiredLabel => 'Your name (required)';
  @override
  String get nameOptionalLabel => 'Your name (optional)';
  @override
  String get nameHelper => 'Shown on the table, so everyone knows who ordered';
  @override
  String get nameRequiredError => 'Enter a name to send';
  @override
  String get tableLabel => 'Table';
  @override
  String get tableFromQrHelper => "From the table's QR code, cannot be changed";
  @override
  String tableAt(int number) => 'Table $number';
  @override
  String get tableNumberLabel => 'Table number';
  @override
  String get tableEnterToSend => 'Enter the table number to send';
  @override
  String get tableSourceQr => 'from QR';
  @override
  String get tableSourceManual => 'entered manually';
  @override
  String tableKnownHelper(int number, String source) =>
      'Table $number · $source';
  @override
  String get tableInvalid => 'Invalid table number';
  @override
  String onTable(int number) => 'On table $number';
  @override
  String get you => '(you)';

  @override
  String get myOrders => 'My orders';
  @override
  String get usuallyReadyIn => 'usually ready in 5-10 min';
  @override
  String get stepWaiting => 'Waiting';
  @override
  String get stepAccepted => 'Accepted';
  @override
  String get stepPreparing => 'Preparing';
  @override
  String get stepReady => 'Ready';
  @override
  String get stepDelivered => 'Delivered';

  @override
  String get confirmSubmitTitle => 'Send the order?';
  @override
  String totalLine(String total) => 'Total: $total';
  @override
  String get back => 'Back';
  @override
  String get send => 'Send';
  @override
  String get sending => 'Sending...';
  @override
  String orderNumber(int? sequence) => 'Order #$sequence';
  @override
  String get newOrder => 'New order';
  @override
  String couldNotSend(String reason) => 'Could not send: $reason';
  @override
  String get retry => 'Retry';
  @override
  String get submitOrder => 'Send the order';

  @override
  String get waiterTitle => 'Waiter · new orders';
  @override
  String get refresh => 'Refresh';
  @override
  String get logout => 'Log out';
  @override
  String get nothingWaiting => 'Nothing waiting';
  @override
  String get sectionRequests => 'Requests';
  @override
  String get sectionNewOrders => 'New orders';
  @override
  String get sectionInProgress => 'In progress';
  @override
  String get customerFallback => 'Customer';
  @override
  String get confirmOrder => 'Confirm';
  @override
  String get resolve => 'Resolve';
  @override
  String get markReady => 'Ready';
  @override
  String get markDelivered => 'Delivered';
  @override
  String sectionCount(String label, int count) => '$label ($count)';
  @override
  String waitedFor(String duration) => 'for $duration';
  @override
  String acceptedIn(String duration) => 'accepted in $duration';
  @override
  String readyFor(String duration) => 'ready for $duration';

  @override
  String get ownerTitle => 'Owner · summary';
  @override
  String get today => 'Today';
  @override
  String get now => 'Now';
  @override
  String get ordersToday => 'Orders today';
  @override
  String get revenueToday => 'Revenue today';
  @override
  String get avgAcceptanceLabel => 'Avg acceptance time';
  @override
  String get avgDeliveryLabel => 'Avg delivery to table';
  @override
  String get toAccept => 'To accept';
  @override
  String get openRequestsLabel => 'Open requests';
  @override
  String get statsUnavailable => 'Statistics unavailable';
  @override
  String get revenuePerDay => 'Revenue per day';
  @override
  String get avgOrderValue => 'Average order value';
  @override
  String get vsPreviousDay => 'Vs the previous day';
  @override
  String get salesByHour => 'Sales by hour';
  @override
  String get topProducts => 'Top products';
  @override
  String get ordersWord => 'orders';
  @override
  String units(int count) => '$count pcs';

  @override
  String get staffAccess => 'Staff access';
  @override
  String get ownerAccess => 'Owner access';
  @override
  String get enterAccessCode => 'Enter the access code';
  @override
  String get codeLabel => 'Code';
  @override
  String get wrongCode => 'Wrong code';
  @override
  String get enterButton => 'Enter';

  @override
  String get adminTitle => 'Operator';
  @override
  String get operatorTokenLabel => 'Operator token';
  @override
  String get loadMetrics => 'Load';
  @override
  String venueCountLabel(int count) => '$count active venues';
  @override
  String get venueColumn => 'Venue';
  @override
  String get ordersColumn => 'Orders';
  @override
  String get usersColumn => 'Users';
  @override
  String get noOperatorData => 'No venue activity yet.';
  @override
  String get operatorLoadError => 'Could not load. Check the operator token.';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get venueNameLabel => 'Venue name';
  @override
  String get brandColorsTitle => 'Brand colours';
  @override
  String get colorBackground => 'Background';
  @override
  String get colorSurface => 'Cards';
  @override
  String get colorPrimary => 'Primary accent';
  @override
  String get colorAccent => 'Secondary accent';
  @override
  String get colorInvalid => 'Invalid colour';
  @override
  String get settingsPreview => 'Preview';
  @override
  String get saveSettings => 'Save';
  @override
  String get settingsSaved => 'Saved.';
  @override
  String get settingsSaveFailed => 'Could not save. Check your owner access.';
  @override
  String get openSettings => 'Settings';
}
