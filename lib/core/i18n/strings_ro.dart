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
  String get becomeLoyal => 'Devino client fidel';
  @override
  String get loyalCustomer => 'Client fidel';
  @override
  String get loyalIntro => 'Comenzi mai rapide, istoric și oferte';
  @override
  String get loyalEnroll => 'Înscrie-te';
  @override
  String get leaveLoyalty => 'Renunță la fidelitate';
  @override
  String get chooseTablePrompt => 'Spune-ne la ce masă ești ca să poți comanda';
  @override
  String get chooseTable => 'Alege masa';
  @override
  String get scanTable => 'Scanează masa';
  @override
  String get account => 'Contul meu';
  @override
  String get orderHistory => 'Istoric comenzi';
  @override
  String get noHistoryYet => 'Nicio comandă încă';
  @override
  String get rewards => 'Recompense';
  @override
  String get pointsLabel => 'puncte';
  @override
  String points(int value) => '$value puncte';
  @override
  String pointsToNext(int value, String reward) =>
      'Încă $value puncte pentru „$reward"';
  @override
  String get allRewardsUnlocked => 'Ai deblocat toate recompensele';
  @override
  String get rewardUnlocked => 'Deblocat';
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

  @override
  String get waiterTitle => 'Ospătar · comenzi noi';
  @override
  String get refresh => 'Reîmprospătează';
  @override
  String get logout => 'Ieși';
  @override
  String get nothingWaiting => 'Nimic în așteptare';
  @override
  String get sectionRequests => 'Cereri';
  @override
  String get sectionNewOrders => 'Comenzi noi';
  @override
  String get sectionInProgress => 'În lucru';
  @override
  String get customerFallback => 'Client';
  @override
  String get confirmOrder => 'Confirmă';
  @override
  String get resolve => 'Rezolvă';
  @override
  String get markReady => 'Gata';
  @override
  String get markDelivered => 'Livrat';
  @override
  String sectionCount(String label, int count) => '$label ($count)';
  @override
  String waitedFor(String duration) => 'de $duration';
  @override
  String acceptedIn(String duration) => 'acceptată în $duration';
  @override
  String readyFor(String duration) => 'gata de $duration';

  @override
  String get ownerTitle => 'Patron · sumar';
  @override
  String get today => 'Azi';
  @override
  String get now => 'Acum';
  @override
  String get ordersToday => 'Comenzi azi';
  @override
  String get revenueToday => 'Încasări azi';
  @override
  String get avgAcceptanceLabel => 'Timp mediu preluare';
  @override
  String get avgDeliveryLabel => 'Timp mediu livrare la masă';
  @override
  String get toAccept => 'De preluat';
  @override
  String get openRequestsLabel => 'Cereri deschise';
  @override
  String get statsUnavailable => 'Statisticile nu sunt disponibile';
  @override
  String get revenuePerDay => 'Încasări pe zi';

  @override
  String get staffAccess => 'Acces staff';
  @override
  String get ownerAccess => 'Acces patron';
  @override
  String get enterAccessCode => 'Introdu codul de acces';
  @override
  String get codeLabel => 'Cod';
  @override
  String get wrongCode => 'Cod greșit';
  @override
  String get enterButton => 'Intră';
}
