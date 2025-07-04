// ignore_for_file: file_names, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeographyService {
  final String _baseUrl = "https://api.apilayer.com/geography";

  // Fetch all currencies
  Future<List<Map<String, String>>> fetchCurrencies() async {
    final String apiKey = dotenv.env['GEOGRAPHY_API_KEY'] ?? '';
    final url = Uri.parse("$_baseUrl/currencies");
    print("Currency API URL: $url");
    print("API key used: $apiKey");

    final response = await http.get(url, headers: {'apikey': apiKey});

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<Map<String, String>> currencies = [];
      for (final entry in data.entries) {
        currencies.add({
          "code": entry.key,
          "symbol":
              entry.value['symbol_native'] ??
              entry.value['symbol'] ??
              entry.key,
        });
      }
      return currencies;
    } else {
      print("Failed to fetch currencies: ${response.statusCode}");
      // ✅ Optional fallback so UI does not hang
      return [
        {"code": "USD", "symbol": "\$"},
        {"code": "EUR", "symbol": "€"},
        {"code": "JPY", "symbol": "¥"},
      ];
    }
  }

  // Get country by name
  Future<Map<String, dynamic>?> getCountryByName(String countryName) async {
    final String apiKey = dotenv.env['GEOGRAPHY_API_KEY'] ?? '';
    final url = Uri.parse("$_baseUrl/country/name/$countryName");

    final response = await http.get(url, headers: {'apikey': apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      print("Failed to fetch country info: ${response.statusCode}");
      return null;
    }
  }

  // Get currency by code
  Future<Map<String, dynamic>?> getCurrencyByCode(String code) async {
    final String apiKey = dotenv.env['GEOGRAPHY_API_KEY'] ?? '';
    final url = Uri.parse("$_baseUrl/currency/code/$code");

    final response = await http.get(url, headers: {'apikey': apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      print("Failed to fetch currency info: ${response.statusCode}");
      return null;
    }
  }

  // Get countries using a currency
  Future<List<dynamic>?> getCountriesByCurrency(String currencyCode) async {
    final String apiKey = dotenv.env['GEOGRAPHY_API_KEY'] ?? '';
    final url = Uri.parse("$_baseUrl/countries/currency/$currencyCode");

    final response = await http.get(url, headers: {'apikey': apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as List<dynamic>;
    } else {
      print("Failed to fetch countries by currency: ${response.statusCode}");
      return null;
    }
  }

  // Get countries by region
  Future<List<dynamic>?> getCountriesByRegion(String region) async {
    final String apiKey = dotenv.env['GEOGRAPHY_API_KEY'] ?? '';
    final url = Uri.parse("$_baseUrl/countries/region/$region");

    final response = await http.get(url, headers: {'apikey': apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data as List<dynamic>;
    } else {
      print("Failed to fetch countries by region: ${response.statusCode}");
      return null;
    }
  }
}
