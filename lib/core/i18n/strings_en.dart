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
}
