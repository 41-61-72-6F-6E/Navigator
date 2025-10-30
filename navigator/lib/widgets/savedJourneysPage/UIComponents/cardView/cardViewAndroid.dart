import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigator/models/journey.dart';
import 'package:navigator/widgets/GeneralUIComponents/refreshJourneyPopUp/refreshJourneyPopUp.dart';
import 'package:navigator/widgets/savedJourneysPage/UIComponents/savedJourneyPageUIUtils.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageModel.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageUIState.dart';
import 'package:navigator/widgets/savedJourneysPage/savedJourneysPageView.dart';

class cardViewAndroid extends StatelessWidget {
  final SavedJourneysPageUIState state;
  final SavedJourneysPageModel model;
  final Color successColor;
  final Color onSuccessColor;
  final Journey journey;
  final bool isFirst;

  const cardViewAndroid({
    super.key,
    required this.state,
    required this.model,
    required this.successColor,
    required this.onSuccessColor,
    required this.journey,
    required this.isFirst
  });

  @override
  Widget build(BuildContext context) {    
    bool delayed = false;
    String timeText = SavedJourneyPageUIUtils.generateJourneyTimeText(journey, false, true);
    Text liveTimeTextP1 = const Text('');
    Text liveTimeTextP2 = const Text('');

    Color yLight = const Color.fromARGB(255, 229, 241, 116);
    Color yDark = const Color.fromARGB(255, 166, 175, 34);
    Color y = yLight;
    Color g = onSuccessColor;

    if (Theme.of(context).brightness == Brightness.dark) {
      y = isFirst ? yDark : yLight;
    } else {
      y = isFirst ? yLight : yDark;
    }

    if (isFirst) {
      g = successColor;
    }

    if (journey.legs.first.departureDelayMinutes != null) {
      delayed = true;
      Color c = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
      c = journey.legs.first.departureDelayMinutes! >= 15
          ? Theme.of(context).colorScheme.error
          : c;
      liveTimeTextP1 = Text(
        SavedJourneyPageUIUtils.generateLiveTimeText(journey, true, false),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
      );
    }

    if (journey.legs.last.arrivalDelayMinutes != null) {
      if (delayed) {
        Color cD = journey.legs.first.departureDelayMinutes! <= 0 ? g : y;
        cD = journey.legs.first.departureDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cD;
        Color cA = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        cA = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : cA;
        liveTimeTextP1 = Text(
          SavedJourneyPageUIUtils.generateLiveTimeText(journey, true, false),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cD),
        );
        liveTimeTextP2 = Text(
          SavedJourneyPageUIUtils.generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cA),
        );
      } else {
        delayed = true;
        Color c = journey.legs.last.arrivalDelayMinutes! <= 0 ? g : y;
        c = journey.legs.last.arrivalDelayMinutes! >= 15
            ? Theme.of(context).colorScheme.error
            : c;
        liveTimeTextP2 = Text(
          SavedJourneyPageUIUtils.generateLiveTimeText(journey, false, true),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c),
        );
        liveTimeTextP1 = Text(
          '          ',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
    }

    return Padding(
      padding: isFirst
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isFirst ? 16 : 16.0,
          horizontal: 16,
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trip_origin,
                          color: isFirst
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            journey.legs.first.origin.name,
                            maxLines: 2,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: isFirst
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    SvgPicture.asset(
                      "assets/Icon/go_to_line.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isFirst
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                        BlendMode.srcIn,
                      ),
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/Icon/distance.svg",
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            isFirst
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            journey.legs.last.destination.name,
                            maxLines: 2,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: isFirst
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: isFirst
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  timeText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: isFirst
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (delayed)
                                Row(
                                  children: [
                                    liveTimeTextP1,
                                    Text(
                                      ' - ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: isFirst
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    liveTimeTextP2,
                                  ],
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        SavedJourneyPageUIUtils.buildModes(
                          context,
                          journey,
                          isFirst
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.errorContainer,
                          ),
                          onPressed: () {},
                          label: Text(
                            'no Ticket',
                            style:
                                Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: SvgPicture.asset(
                            "assets/Icon/transit_ticket.svg",
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onErrorContainer,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}