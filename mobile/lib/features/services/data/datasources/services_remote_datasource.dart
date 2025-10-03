import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/about_info_model.dart';

abstract class ServicesRemoteDataSource {
  Future<AboutInfoModel> getAboutInfo();
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final ApiClient apiClient;

  ServicesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AboutInfoModel> getAboutInfo() async {
    try {
      final response = await apiClient.get('/about.json');
      return AboutInfoModel.fromJson(response.data);
    } catch (e) {
      throw NetworkFailure('Failed to fetch about info: ${e.toString()}');
    }
  }
}
