import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Travel Wizards iconography system with travel-specific icons.
///
/// This class provides a centralized icon system for all travel-related
/// functionality, ensuring consistent visual language throughout the app.
class TravelIcons {
  TravelIcons._();

  // ================== Transportation Icons ==================

  /// Flight/airplane icon
  static const IconData flight = Symbols.flight;

  /// Car/road trip icon
  static const IconData car = Symbols.directions_car;

  /// Train icon
  static const IconData train = Symbols.train;

  /// Bus icon
  static const IconData bus = Symbols.directions_bus;

  /// Ship/cruise icon
  static const IconData ship = Symbols.directions_boat;

  /// Bicycle icon
  static const IconData bicycle = Symbols.directions_bike;

  /// Walking icon
  static const IconData walking = Symbols.directions_walk;

  /// Taxi/ride-share icon
  static const IconData taxi = Symbols.local_taxi;

  /// Subway/metro icon
  static const IconData subway = Symbols.subway;

  // ================== Accommodation Icons ==================

  /// Hotel icon
  static const IconData hotel = Symbols.hotel;

  /// Hostel/budget accommodation icon
  static const IconData hostel = Symbols.single_bed;

  /// Airbnb/rental icon
  static const IconData rental = Symbols.home;

  /// Camping icon
  static const IconData camping = Symbols.camping;

  /// Resort icon
  static const IconData resort = Symbols.beach_access;

  /// Luxury accommodation icon
  static const IconData luxury = Symbols.diamond;

  // ================== Activity Type Icons ==================

  /// Adventure activities
  static const IconData adventure = Symbols.landscape;

  /// Beach activities
  static const IconData beach = Symbols.beach_access;

  /// Hiking/outdoor activities
  static const IconData hiking = Symbols.hiking;

  /// Cultural/museums
  static const IconData cultural = Symbols.museum;

  /// Food & dining
  static const IconData food = Symbols.restaurant;

  /// Shopping
  static const IconData shopping = Symbols.shopping_bag;

  /// Nightlife
  static const IconData nightlife = Symbols.local_bar;

  /// Sports/fitness
  static const IconData sports = Symbols.fitness_center;

  /// Family activities
  static const IconData family = Symbols.family_restroom;

  /// Photography/sightseeing
  static const IconData sightseeing = Symbols.photo_camera;

  // ================== Weather & Climate Icons ==================

  /// Sunny/clear weather
  static const IconData sunny = Symbols.wb_sunny;

  /// Partly cloudy
  static const IconData partlyCloudy = Symbols.partly_cloudy_day;

  /// Cloudy
  static const IconData cloudy = Symbols.cloud;

  /// Rainy
  static const IconData rainy = Symbols.rainy;

  /// Snowy
  static const IconData snowy = Symbols.ac_unit;

  /// Stormy
  static const IconData stormy = Symbols.thunderstorm;

  /// Hot temperature
  static const IconData hot = Symbols.device_thermostat;

  /// Cold temperature
  static const IconData cold = Symbols.severe_cold;

  // ================== Trip Planning Icons ==================

  /// Calendar/dates
  static const IconData calendar = Symbols.calendar_month;

  /// Budget/money
  static const IconData budget = Symbols.attach_money;

  /// Itinerary/schedule
  static const IconData itinerary = Symbols.schedule;

  /// Map/navigation
  static const IconData map = Symbols.map;

  /// Location/destination
  static const IconData location = Symbols.location_on;

  /// Passport/documents
  static const IconData passport = Symbols.description;

  /// Luggage/packing
  static const IconData luggage = Symbols.luggage;

  /// Checklist
  static const IconData checklist = Symbols.checklist;

  // ================== Status & UI Icons ==================

  /// Booked/confirmed
  static const IconData booked = Symbols.check_circle;

  /// Pending/in-progress
  static const IconData pending = Symbols.schedule;

  /// Cancelled/error
  static const IconData cancelled = Symbols.cancel;

  /// Draft/planning
  static const IconData draft = Symbols.edit;

  /// Favorite/wishlist
  static const IconData favorite = Symbols.favorite;

  /// Share
  static const IconData share = Symbols.share;

  /// More options
  static const IconData more = Symbols.more_vert;

  /// Search
  static const IconData search = Symbols.search;

  /// Filter
  static const IconData filter = Symbols.filter_list;

  /// Settings
  static const IconData settings = Symbols.settings;

  // ================== Special Travel Icons ==================

  /// Travel concierge/AI assistant
  static const IconData concierge = Symbols.support_agent;

  /// Trip recommendations
  static const IconData recommendations = Symbols.recommend;

  /// Travel guides
  static const IconData guide = Symbols.menu_book;

  /// Emergency/help
  static const IconData emergency = Symbols.local_hospital;

  /// Currency exchange
  static const IconData currency = Symbols.currency_exchange;

  /// Time zone
  static const IconData timezone = Symbols.schedule;

  /// Language/translation
  static const IconData language = Symbols.translate;

  /// Visa/travel requirements
  static const IconData visa = Symbols.assignment;

  // ================== Utility Methods ==================

  /// Get transportation icon by type
  static IconData getTransportationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
      case 'plane':
      case 'airplane':
        return flight;
      case 'car':
      case 'drive':
      case 'driving':
        return car;
      case 'train':
      case 'railway':
        return train;
      case 'bus':
        return bus;
      case 'ship':
      case 'boat':
      case 'cruise':
        return ship;
      case 'bicycle':
      case 'bike':
      case 'cycling':
        return bicycle;
      case 'walk':
      case 'walking':
        return walking;
      case 'taxi':
      case 'uber':
      case 'lyft':
        return taxi;
      case 'subway':
      case 'metro':
        return subway;
      default:
        return location; // Default location icon
    }
  }

  /// Get activity icon by type
  static IconData getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'adventure':
      case 'outdoor':
        return adventure;
      case 'beach':
      case 'water':
        return beach;
      case 'hiking':
      case 'trekking':
        return hiking;
      case 'cultural':
      case 'museum':
      case 'heritage':
        return cultural;
      case 'food':
      case 'dining':
      case 'restaurant':
        return food;
      case 'shopping':
        return shopping;
      case 'nightlife':
      case 'bar':
      case 'club':
        return nightlife;
      case 'sports':
      case 'fitness':
        return sports;
      case 'family':
      case 'kids':
        return family;
      case 'sightseeing':
      case 'photography':
        return sightseeing;
      default:
        return location; // Default location icon
    }
  }

  /// Get accommodation icon by type
  static IconData getAccommodationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return hotel;
      case 'hostel':
      case 'budget':
        return hostel;
      case 'rental':
      case 'airbnb':
      case 'apartment':
        return rental;
      case 'camping':
      case 'tent':
        return camping;
      case 'resort':
        return resort;
      case 'luxury':
      case 'premium':
        return luxury;
      default:
        return hotel; // Default hotel icon
    }
  }

  /// Get weather icon by condition
  static IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return sunny;
      case 'partly cloudy':
      case 'partly_cloudy':
        return partlyCloudy;
      case 'cloudy':
      case 'overcast':
        return cloudy;
      case 'rainy':
      case 'rain':
        return rainy;
      case 'snowy':
      case 'snow':
        return snowy;
      case 'stormy':
      case 'storm':
      case 'thunder':
        return stormy;
      case 'hot':
        return hot;
      case 'cold':
        return cold;
      default:
        return partlyCloudy; // Default weather icon
    }
  }

  /// Get status icon by status
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
      case 'confirmed':
      case 'active':
        return booked;
      case 'pending':
      case 'in-progress':
      case 'processing':
        return pending;
      case 'cancelled':
      case 'failed':
      case 'error':
        return cancelled;
      case 'draft':
      case 'planning':
      case 'not-started':
        return draft;
      default:
        return draft; // Default status icon
    }
  }
}

/// Extension on IconData to add travel-specific icon styling
extension TravelIconData on IconData {
  /// Create an Icon widget with travel-themed sizing
  Icon asIcon({double? size, Color? color, String? semanticLabel}) {
    return Icon(
      this,
      size: size ?? 24.0,
      color: color,
      semanticLabel: semanticLabel,
    );
  }

  /// Create a small travel icon (16px)
  Icon asSmallIcon({Color? color, String? semanticLabel}) {
    return asIcon(size: 16.0, color: color, semanticLabel: semanticLabel);
  }

  /// Create a medium travel icon (24px) - default
  Icon asMediumIcon({Color? color, String? semanticLabel}) {
    return asIcon(size: 24.0, color: color, semanticLabel: semanticLabel);
  }

  /// Create a large travel icon (32px)
  Icon asLargeIcon({Color? color, String? semanticLabel}) {
    return asIcon(size: 32.0, color: color, semanticLabel: semanticLabel);
  }

  /// Create an extra large travel icon (48px)
  Icon asXLargeIcon({Color? color, String? semanticLabel}) {
    return asIcon(size: 48.0, color: color, semanticLabel: semanticLabel);
  }
}
