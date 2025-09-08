class JourneySettings {
  bool? nationalExpress;
  bool? national;
  bool? regionalExpress;
  bool? regional;
  bool? suburban;
  bool? subway;
  bool? tram;
  bool? bus;
  bool? ferry;
  bool? deutschlandTicketConnectionsOnly;
  bool? accessibility;
  String? walkingSpeed;
  int? transferTime;

  JourneySettings({
    this.nationalExpress = true,
    this.national = true,
    this.regionalExpress = true,
    this.regional = true,
    this.suburban = true,
    this.subway = true,
    this.tram = true,
    this.bus = true,
    this.ferry = true,
    this.deutschlandTicketConnectionsOnly = false,
    this.accessibility = false,
    this.walkingSpeed = 'normal',
    this.transferTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'nationalExpress': nationalExpress,
      'national': national,
      'regionalExpress': regionalExpress,
      'regional': regional,
      'suburban': suburban,
      'subway': subway,
      'tram': tram,
      'bus': bus,
      'ferry': ferry,
      'deutschlandTicketConnectionsOnly': deutschlandTicketConnectionsOnly,
      'accessibility': accessibility,
      'walkingSpeed': walkingSpeed,
      'transferTime': transferTime,
    };
  }
}