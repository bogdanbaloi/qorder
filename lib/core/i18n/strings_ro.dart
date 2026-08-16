import 'app_strings.dart';

/// Romanian UI strings (the default).
class StringsRo implements AppStrings {
  const StringsRo();

  @override
  AppLanguage get language => AppLanguage.ro;

  @override
  String get menuTitle => 'Meniu';
  @override
  String menuTitleForTable(int table) => 'Meniu · Masa $table';
  @override
  String get callWaiter => 'Cheamă ospătarul';
  @override
  String get bringBill => 'Adu nota';
  @override
  String get cart => 'Coș';
  @override
  String get searchHint => 'Caută în meniu';
  @override
  String get onlyAvailableNow => 'Doar disponibile acum';
  @override
  String get nothingFound => 'Nimic găsit';
  @override
  String get couldNotLoadMenu => 'Nu am putut încărca meniul.';
  @override
  String get waiterNotified => 'Ospătarul a fost anunțat.';
  @override
  String get billOnTheWay => 'Am cerut nota. Ospătarul vine.';
  @override
  String get unavailableNow => 'indisponibil acum';
  @override
  String availableAt(String hours) => 'disponibil $hours';
  @override
  String get addToCart => 'Adaugă în coș';
  @override
  String get quantity => 'Cantitate';
  @override
  String addedToCart(String name) => '$name adăugat';
  @override
  String cartFab(int count, String total) => 'Coș ($count) · $total';

  @override
  String get orderTitle => 'Comanda';
  @override
  String get cartEmpty => 'Coșul e gol';
  @override
  String get seeMenu => 'Vezi meniul';
  @override
  String get total => 'Total';
  @override
  String youSaved(String amount) => 'Ai economisit $amount';
  @override
  String get nameRequiredLabel => 'Numele tău (necesar)';
  @override
  String get nameOptionalLabel => 'Numele tău (opțional)';
  @override
  String get nameHelper => 'Apare pe masă, ca să se știe cine a comandat';
  @override
  String get nameRequiredError => 'Scrie un nume ca să poți trimite';
  @override
  String get tableLabel => 'Masa';
  @override
  String get tableFromQrHelper =>
      'Din codul QR de pe masă, nu se poate schimba';
  @override
  String tableAt(int number) => 'Masa $number';
  @override
  String get tableNumberLabel => 'Numărul mesei';
  @override
  String get tableEnterToSend => 'Introdu numărul mesei ca să poți trimite';
  @override
  String get tableSourceQr => 'din QR';
  @override
  String get tableSourceManual => 'introdusă manual';
  @override
  String tableKnownHelper(int number, String source) =>
      'Masa $number · $source';
  @override
  String get tableInvalid => 'Număr de masă invalid';
  @override
  String onTable(int number) => 'Pe masa $number';
  @override
  String get you => '(tu)';

  @override
  String get myOrders => 'Comenzile mele';
  @override
  String get usuallyReadyIn => 'de obicei gata în 5-10 min';
  @override
  String get stepWaiting => 'Așteaptă';
  @override
  String get stepAccepted => 'Preluată';
  @override
  String get stepPreparing => 'În pregătire';
  @override
  String get stepReady => 'Gata';

  @override
  String get confirmSubmitTitle => 'Trimiți comanda?';
  @override
  String totalLine(String total) => 'Total: $total';
  @override
  String get back => 'Înapoi';
  @override
  String get send => 'Trimite';
  @override
  String get sending => 'Se trimite...';
  @override
  String orderNumber(int? sequence) => 'Comandă #$sequence';
  @override
  String get newOrder => 'Comandă nouă';
  @override
  String couldNotSend(String reason) => 'Nu am putut trimite: $reason';
  @override
  String get retry => 'Reîncearcă';
  @override
  String get submitOrder => 'Trimite comanda';
}
