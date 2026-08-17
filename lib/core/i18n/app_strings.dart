/// The languages the app UI is offered in. A new language is a new value plus a
/// new [AppStrings] implementation, no widget changes (Open/Closed).
enum AppLanguage {
  ro('ro', 'RO'),
  en('en', 'EN');

  const AppLanguage(this.code, this.label);

  final String code; // persisted / locale code
  final String label; // shown on the toggle

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => ro);
}

/// The UI string table (app chrome only). Menu CONTENT stays as the venue
/// supplies it; only the interface is translated. One implementation per
/// language, so adding a language never touches a widget.
abstract interface class AppStrings {
  AppLanguage get language;

  // Menu screen
  String get menuTitle;
  String menuTitleForTable(int table);
  String get becomeLoyal;
  String get loyalCustomer;
  String get loyalIntro;
  String get loyalEnroll;
  String get leaveLoyalty;
  String get chooseTablePrompt;
  String get chooseTable;
  String get scanTable;
  String get account;
  String get orderHistory;
  String get noHistoryYet;
  String get rewards;
  String get pointsLabel;
  String points(int value);
  String pointsToNext(int value, String reward);
  String get allRewardsUnlocked;
  String get rewardUnlocked;
  String get callWaiter;
  String get bringBill;
  String get cart;
  String get searchHint;
  String get onlyAvailableNow;
  String get nothingFound;
  String get couldNotLoadMenu;
  String get waiterNotified;
  String get billOnTheWay;
  String get unavailableNow;
  String availableAt(String hours);
  String get addToCart;
  String get quantity;
  String addedToCart(String name);
  String cartFab(int count, String total);

  // Cart screen
  String get orderTitle;
  String get cartEmpty;
  String get seeMenu;
  String get total;
  String youSaved(String amount);
  String get nameRequiredLabel;
  String get nameOptionalLabel;
  String get nameHelper;
  String get nameRequiredError;
  String get tableLabel;
  String get tableFromQrHelper;
  String tableAt(int number);
  String get tableNumberLabel;
  String get tableEnterToSend;
  String get tableSourceQr;
  String get tableSourceManual;
  String tableKnownHelper(int number, String source);
  String get tableInvalid;
  String onTable(int number);
  String get you;

  // Order status steps
  String get myOrders;
  String get usuallyReadyIn;
  String get stepWaiting;
  String get stepAccepted;
  String get stepPreparing;
  String get stepReady;

  // Submit flow
  String get confirmSubmitTitle;
  String totalLine(String total);
  String get back;
  String get send;
  String get sending;
  String orderNumber(int? sequence);
  String get newOrder;
  String couldNotSend(String reason);
  String get retry;
  String get submitOrder;

  // Staff (waiter) surface
  String get waiterTitle;
  String get refresh;
  String get logout;
  String get nothingWaiting;
  String get sectionRequests;
  String get sectionNewOrders;
  String get sectionInProgress;
  String get customerFallback;
  String get confirmOrder;
  String get resolve;
  String get markReady;
  String get markDelivered;
  String sectionCount(String label, int count);
  String waitedFor(String duration);
  String acceptedIn(String duration);
  String readyFor(String duration);

  // Owner dashboard
  String get ownerTitle;
  String get today;
  String get now;
  String get ordersToday;
  String get revenueToday;
  String get avgAcceptanceLabel;
  String get avgDeliveryLabel;
  String get toAccept;
  String get openRequestsLabel;
  String get statsUnavailable;
  String get revenuePerDay;
  String get avgOrderValue;
  String get vsPreviousDay;
  String get salesByHour;
  String get topProducts;
  String get ordersWord;
  String units(int count);

  // Role access gate
  String get staffAccess;
  String get ownerAccess;
  String get enterAccessCode;
  String get codeLabel;
  String get wrongCode;
  String get enterButton;
}
