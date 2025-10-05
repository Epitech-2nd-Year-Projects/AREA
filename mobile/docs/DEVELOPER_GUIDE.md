# AREA Mobile - Developer Documentation

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Project Structure](#3-project-structure)
4. [Getting Started](#4-getting-started)
5. [Core Concepts](#5-core-concepts)
6. [Adding New Features](#6-adding-new-features)
7. [State Management](#7-state-management)
8. [Navigation](#8-navigation)
9. [API Integration](#9-api-integration)
10. [Design System](#10-design-system)
11. [Best Practices](#11-best-practices)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Project Overview

### 1.1 Purpose

AREA (Action-REAction) is an automation platform mobile application that allows users to connect various services and create automated workflows. When an **Action** (trigger) occurs on one service, a **REAction** (response) is executed on another service.

### 1.2 Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: flutter_bloc / Cubit
- **Dependency Injection**: get_it
- **Routing**: go_router
- **HTTP Client**: dio
- **Storage**: shared_preferences, flutter_secure_storage
- **Functional Programming**: dartz (Either for error handling)

### 1.3 Key Features

- User authentication (email/password + OAuth2)
- Service management and subscriptions
- AREA (automation) creation and management
- Multi-platform support (Android/iOS)
- Responsive design with accessibility support

---

## 2. Architecture

### 2.1 Clean Architecture Layers

The project follows **Clean Architecture** principles with three main layers:

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  (UI, Widgets, BLoC/Cubit, Pages)      │
└─────────────────────────────────────────┘
                  ↓↑
┌─────────────────────────────────────────┐
│          DOMAIN LAYER                   │
│  (Entities, UseCases, Repositories)     │
└─────────────────────────────────────────┘
                  ↓↑
┌─────────────────────────────────────────┐
│           DATA LAYER                    │
│  (Models, DataSources, Repository Impl) │
└─────────────────────────────────────────┘
```

#### 2.1.1 Presentation Layer

**Responsibility**: UI components, user interactions, state management

**Key Components**:
- **Pages**: Full-screen views (e.g., `LoginPage`, `ServicesListPage`)
- **Widgets**: Reusable UI components
- **BLoC/Cubit**: State management logic
- **Router**: Navigation configuration

**Rules**:
- ✅ Can depend on Domain layer
- ❌ Cannot depend on Data layer
- ✅ Handles UI state and events
- ❌ No business logic

#### 2.1.2 Domain Layer

**Responsibility**: Business logic, core entities, contracts

**Key Components**:
- **Entities**: Core business models (e.g., `User`, `Service`, `Area`)
- **Use Cases**: Single-responsibility business operations
- **Repository Interfaces**: Contracts for data access
- **Value Objects**: Domain-specific types with validation
- **Exceptions**: Domain-specific errors

**Rules**:
- ❌ No dependencies on other layers
- ✅ Pure Dart code only
- ✅ Contains all business rules
- ✅ Framework-agnostic

#### 2.1.3 Data Layer

**Responsibility**: Data persistence, API communication, data transformation

**Key Components**:
- **Models**: Data transfer objects (DTOs)
- **Data Sources**: Remote (API) and Local (storage)
- **Repository Implementations**: Concrete implementations of domain contracts
- **Mappers**: Transform models to entities

**Rules**:
- ✅ Depends on Domain layer (implements interfaces)
- ✅ Handles data serialization/deserialization
- ✅ Manages caching strategies
- ❌ No UI dependencies

### 2.2 Dependency Flow

```dart
// CORRECT ✅
Presentation → Domain ← Data

// INCORRECT ❌
Presentation → Data
Domain → Presentation
Domain → Data (direct implementation)
```

### 2.3 Dependency Injection

We use **get_it** for service locator pattern. All dependencies are registered in `lib/core/di/injection.dart`:

```dart
final sl = GetIt.instance;

Future<void> initCoreDependencies() async {
  // Register singletons
  sl.registerLazySingleton<ApiClient>(() => ApiClient(...));
  
  // Register factories
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
}
```

**Registration Types**:
- `registerSingleton`: Single instance for app lifetime
- `registerLazySingleton`: Created on first access, then reused
- `registerFactory`: New instance every time

---

## 3. Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # Root widget configuration
│
├── core/                              # Shared infrastructure
│   ├── design_system/                 # UI/UX constants
│   │   ├── app_colors.dart           # Color palette
│   │   ├── app_typography.dart       # Text styles
│   │   └── app_spacing.dart          # Spacing constants
│   │
│   ├── di/                           # Dependency injection
│   │   └── injection.dart            # Service locator setup
│   │
│   ├── navigation/                   # Routing configuration
│   │   ├── app_navigation.dart       # Navigation helpers
│   │   ├── main_scaffold.dart        # Bottom nav scaffold
│   │   └── widgets/                  # Nav-related widgets
│   │
│   ├── network/                      # HTTP client setup
│   │   ├── api_client.dart           # Dio configuration
│   │   ├── api_config.dart           # API constants
│   │   ├── interceptors/             # Request/response interceptors
│   │   └── exceptions/               # Network error handling
│   │
│   ├── storage/                      # Local data persistence
│   │   ├── local_prefs_manager.dart  # SharedPreferences wrapper
│   │   ├── secure_storage_manager.dart # Secure storage
│   │   ├── cache_manager.dart        # In-memory cache
│   │   └── storage_keys.dart         # Storage key constants
│   │
│   └── error/                        # Error handling
│       └── failures.dart             # Failure types
│
└── features/                         # Feature modules
    │
    ├── auth/                         # Authentication feature
    │   ├── domain/
    │   │   ├── entities/             # User, AuthSession
    │   │   ├── repositories/         # AuthRepository interface
    │   │   ├── use_cases/            # Login, Register, etc.
    │   │   ├── value_objects/        # Email, Password
    │   │   └── exceptions/           # Auth-specific errors
    │   │
    │   ├── data/
    │   │   ├── models/               # UserModel, DTOs
    │   │   ├── datasources/          # Remote/Local data sources
    │   │   └── repositories/         # Repository implementation
    │   │
    │   └── presentation/
    │       ├── blocs/                # BLoC/Cubit state management
    │       ├── pages/                # Login, Register pages
    │       ├── widgets/              # Reusable auth widgets
    │       └── router/               # Auth routing config
    │
    ├── services/                     # Services feature
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │
    └── areas/                        # Automation feature
        ├── domain/
        ├── data/
        └── presentation/
```

### 3.1 Feature Module Structure

Each feature follows the same structure:

```
feature_name/
├── domain/
│   ├── entities/              # Pure business objects
│   ├── repositories/          # Abstract contracts
│   ├── use_cases/             # Business operations
│   ├── value_objects/         # Validated domain types
│   └── exceptions/            # Feature-specific errors
│
├── data/
│   ├── models/                # JSON serializable DTOs
│   ├── datasources/           # API/DB access
│   │   ├── remote/            # HTTP requests
│   │   └── local/             # Local storage
│   └── repositories/          # Interface implementations
│
└── presentation/
    ├── blocs/                 # State management
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    │
    ├── pages/                 # Full screens
    ├── widgets/               # Reusable components
    └── router/                # Feature routing
```

---

## 4. Getting Started

### 4.1 Prerequisites

```bash
# Flutter SDK
flutter --version  # Should be >= 3.0.0

# Dependencies
flutter pub get

# Generate code (if needed)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4.2 Environment Setup

1. **Configure API base URL** in `lib/core/network/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = "http://10.0.2.2:8080"; // Android emulator
  // static const String baseUrl = "http://localhost:8080"; // iOS simulator
}
```

2. **Set up OAuth credentials** (when implemented):

```dart
// Add to environment variables or secure config
const googleClientId = "YOUR_CLIENT_ID";
const facebookAppId = "YOUR_APP_ID";
```

### 4.3 Running the App

```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d iPhone

# Build release APK
flutter build apk --release

# Build iOS release
flutter build ios --release
```

---

## 5. Core Concepts

### 5.1 State Management with BLoC

We use **flutter_bloc** for state management. Each feature has its own BLoC/Cubit.

#### BLoC vs Cubit

**Use BLoC when**:
- Complex state logic
- Need event history
- External event sources

**Use Cubit when**:
- Simple state changes
- Direct method calls
- Less boilerplate

#### Example: Creating a Cubit

```dart
// 1. Define State
abstract class MyFeatureState extends Equatable {
  const MyFeatureState();
  @override
  List<Object?> get props => [];
}

class MyFeatureInitial extends MyFeatureState {}
class MyFeatureLoading extends MyFeatureState {}
class MyFeatureLoaded extends MyFeatureState {
  final List<Data> items;
  const MyFeatureLoaded(this.items);
  @override
  List<Object?> get props => [items];
}
class MyFeatureError extends MyFeatureState {
  final String message;
  const MyFeatureError(this.message);
  @override
  List<Object?> get props => [message];
}

// 2. Create Cubit
class MyFeatureCubit extends Cubit<MyFeatureState> {
  final MyRepository _repository;
  
  MyFeatureCubit(this._repository) : super(MyFeatureInitial());
  
  Future<void> loadData() async {
    emit(MyFeatureLoading());
    
    final result = await _repository.getData();
    
    result.fold(
      (failure) => emit(MyFeatureError(failure.message)),
      (data) => emit(MyFeatureLoaded(data)),
    );
  }
}
```

#### Using in UI

```dart
class MyFeaturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyFeatureCubit(sl())..loadData(),
      child: BlocBuilder<MyFeatureCubit, MyFeatureState>(
        builder: (context, state) {
          if (state is MyFeatureLoading) {
            return CircularProgressIndicator();
          }
          if (state is MyFeatureError) {
            return Text('Error: ${state.message}');
          }
          if (state is MyFeatureLoaded) {
            return ListView(
              children: state.items.map((item) => Text(item.name)).toList(),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}
```

### 5.2 Error Handling with Either

We use **dartz** package's `Either<L, R>` for functional error handling:

```dart
// Either<Failure, Success>
Future<Either<Failure, User>> login(Email email, Password password) async {
  try {
    final response = await _dataSource.login(email.value, password.value);
    return Right(response.user.toDomain());
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on UnauthorizedException {
    return Left(UnauthorizedFailure('Invalid credentials'));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}

// Usage
final result = await loginUseCase(email, password);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (user) => print('Success: ${user.email}'),
);
```

### 5.3 Value Objects

Value objects encapsulate validation logic:

```dart
class Email {
  final String value;
  
  Email._(this.value);
  
  factory Email(String input) {
    if (!_isValidEmail(input)) {
      throw InvalidEmailException(input);
    }
    return Email._(input);
  }
  
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$').hasMatch(email);
  }
  
  @override
  String toString() => value;
}

// Usage
try {
  final email = Email('user@example.com'); // ✅ Valid
  final badEmail = Email('invalid'); // ❌ Throws InvalidEmailException
} on InvalidEmailException catch (e) {
  print('Invalid email: ${e.message}');
}
```

### 5.4 Use Cases

Each use case represents a single business operation:

```dart
class GetUserProfile {
  final UserRepository _repository;
  
  GetUserProfile(this._repository);
  
  Future<Either<Failure, User>> call() async {
    return await _repository.getCurrentUser();
  }
}

// Usage in BLoC
final result = await _getUserProfile();
```

---

## 6. Adding New Features

### 6.1 Feature Development Checklist

- [ ] Define domain entities
- [ ] Create repository interface
- [ ] Implement use cases
- [ ] Create data models
- [ ] Implement data sources
- [ ] Implement repository
- [ ] Create state management (BLoC/Cubit)
- [ ] Build UI components
- [ ] Add navigation routes
- [ ] Register dependencies
- [ ] Write tests

### 6.2 Step-by-Step: Adding a "Notifications" Feature

#### Step 1: Create Domain Layer

**Create entity** (`lib/features/notifications/domain/entities/notification.dart`):

```dart
import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  
  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });
  
  @override
  List<Object?> get props => [id, userId, title, message, createdAt, isRead];
}
```

**Create repository interface** (`lib/features/notifications/domain/repositories/notification_repository.dart`):

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<Notification>>> getNotifications();
  Future<Either<Failure, Notification>> markAsRead(String notificationId);
  Future<Either<Failure, bool>> deleteNotification(String notificationId);
}
```

**Create use case** (`lib/features/notifications/domain/use_cases/get_notifications.dart`):

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository _repository;
  
  GetNotifications(this._repository);
  
  Future<Either<Failure, List<Notification>>> call() async {
    return await _repository.getNotifications();
  }
}
```

#### Step 2: Create Data Layer

**Create model** (`lib/features/notifications/data/models/notification_model.dart`):

```dart
import '../../domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required super.createdAt,
    required super.isRead,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
  
  Notification toDomain() {
    return Notification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}
```

**Create remote data source** (`lib/features/notifications/data/datasources/notification_remote_datasource.dart`):

```dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/exceptions/network_exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<NotificationModel> markAsRead(String notificationId);
  Future<bool> deleteNotification(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;
  
  NotificationRemoteDataSourceImpl(this._apiClient);
  
  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/notifications',
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> notificationsJson = response.data!['notifications'];
        return notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }
      
      throw NetworkException('Failed to fetch notifications');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
  
  @override
  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/v1/notifications/$notificationId/read',
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return NotificationModel.fromJson(response.data!['notification']);
      }
      
      throw NetworkException('Failed to mark notification as read');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
  
  @override
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiClient.delete(
        '/v1/notifications/$notificationId',
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
```

**Implement repository** (`lib/features/notifications/data/repositories/notification_repository_impl.dart`):

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/exceptions/network_exceptions.dart';
import '../../../../core/network/exceptions/unauthorized_exception.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  
  NotificationRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<Either<Failure, List<Notification>>> getNotifications() async {
    try {
      final notificationModels = await _remoteDataSource.getNotifications();
      final notifications = notificationModels
          .map((model) => model.toDomain())
          .toList();
      return Right(notifications);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure('Authentication required'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Notification>> markAsRead(String notificationId) async {
    try {
      final notificationModel = await _remoteDataSource.markAsRead(notificationId);
      return Right(notificationModel.toDomain());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> deleteNotification(String notificationId) async {
    try {
      final result = await _remoteDataSource.deleteNotification(notificationId);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
```

#### Step 3: Create Presentation Layer

**Create state** (`lib/features/notifications/presentation/cubit/notifications_state.dart`):

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/notification.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Notification> notifications;
  
  const NotificationsLoaded(this.notifications);
  
  @override
  List<Object?> get props => [notifications];
}

class NotificationsError extends NotificationsState {
  final String message;
  
  const NotificationsError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

**Create cubit** (`lib/features/notifications/presentation/cubit/notifications_cubit.dart`):

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/use_cases/get_notifications.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  late final GetNotifications _getNotifications;
  final NotificationRepository _repository;
  
  NotificationsCubit(this._repository) : super(NotificationsInitial()) {
    _getNotifications = GetNotifications(_repository);
  }
  
  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    
    final result = await _getNotifications();
    
    result.fold(
      (failure) => emit(NotificationsError(_mapFailureToMessage(failure))),
      (notifications) => emit(NotificationsLoaded(notifications)),
    );
  }
  
  Future<void> markAsRead(String notificationId) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      
      final result = await _repository.markAsRead(notificationId);
      
      result.fold(
        (failure) => emit(NotificationsError(_mapFailureToMessage(failure))),
        (updatedNotification) {
          final updatedList = currentState.notifications.map((n) {
            return n.id == notificationId ? updatedNotification : n;
          }).toList();
          
          emit(NotificationsLoaded(updatedList));
        },
      );
    }
  }
  
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure _:
        return 'Network error. Please check your connection.';
      case UnauthorizedFailure _:
        return 'Please log in to view notifications.';
      default:
        return 'Failed to load notifications.';
    }
  }
}
```

**Create page** (`lib/features/notifications/presentation/pages/notifications_page.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(sl())..loadNotifications(),
      child: const _NotificationsPageContent(),
    );
  }
}

class _NotificationsPageContent extends StatelessWidget {
  const _NotificationsPageContent();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationsCubit>().loadNotifications();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is NotificationsLoaded) {
            final notifications = state.notifications;
            
            if (notifications.isEmpty) {
              return const Center(
                child: Text('No notifications yet'),
              );
            }
            
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead 
                        ? AppColors.gray200 
                        : AppColors.primary,
                    child: Icon(
                      notification.isRead 
                          ? Icons.notifications_none 
                          : Icons.notifications_active,
                      color: notification.isRead 
                          ? AppColors.gray600 
                          : Colors.white,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: notification.isRead 
                          ? FontWeight.w400 
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(notification.message),
                  trailing: !notification.isRead
                      ? IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            context.read<NotificationsCubit>()
                                .markAsRead(notification.id);
                          },
                        )
                      : null,
                );
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

#### Step 4: Register Dependencies

Update `lib/core/di/injection.dart`:

```dart
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';

Future<void> initCoreDependencies() async {
  // ... existing code ...
  
  // Notifications
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(sl<ApiClient>()),
  );
  
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<NotificationRemoteDataSource>()),
  );
}
```

#### Step 5: Add Navigation Route

Update `lib/features/auth/presentation/router/auth_router.dart`:

```dart
import '../../../notifications/presentation/pages/notifications_page.dart';

class AuthRouter {
  static List<RouteBase> get routes => [
    ShellRoute(
      // ... existing routes ...
      routes: [
        // ... existing routes ...
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
      ],
    ),
    // ... rest of routes ...
  ];
}
```

---

## 7. State Management

### 7.1 BLoC Pattern Best Practices

#### DO ✅

```dart
// Emit states in order
emit(DataLoading());
final result = await useCase();
result.fold(
  (failure) => emit(DataError(failure.message)),
  (data) => emit(DataLoaded(data)),
);

// Use Equatable for state comparison
class MyState extends Equatable {
  final List<Item> items;
  const MyState(this.items);
  
  @override
  List<Object?> get props => [items];
}

// Handle loading and error states
if (state is MyFeatureLoading) {
  return const CircularProgressIndicator();
}

// Use BlocListener for side effects (navigation, dialogs)
BlocListener<MyBloc, MyState>(
  listener: (context, state) {
    if (state is MySuccess) {
      context.go('/success');
    }
  },
  child: MyWidget(),
)
```

#### DON'T ❌

```dart
// Don't emit multiple states synchronously
emit(Loading());
emit(Loaded(data)); // ❌ Previous state might be skipped

// Don't mutate state directly
final currentState = state as MyLoaded;
currentState.items.add(newItem); // ❌ Mutating state
emit(currentState); // ❌ Same reference, won't trigger rebuild

// Don't use BLoC for local UI state
// Use StatefulWidget or useState hook instead

// Don't access BLoC across features
// Use dependency injection and repositories instead
```

### 7.2 State Management Patterns

#### Loading States

```dart
class MyFeatureState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Data>? data;
  
  const MyFeatureState({
    this.isLoading = false,
    this.error,
    this.data,
  });
  
  MyFeatureState copyWith({
    bool? isLoading,
    String? error,
    List<Data>? data,
  }) {
    return MyFeatureState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
  
  @override
  List<Object?> get props => [isLoading, error, data];
}
```

#### Pagination States

```dart
class PaginatedState extends Equatable {
  final List<Item> items;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;
  
  const PaginatedState({
    required this.items,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.currentPage = 1,
  });
  
  @override
  List<Object?> get props => [items, hasMore, isLoadingMore, currentPage];
}

class MyCubit extends Cubit<PaginatedState> {
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    
    emit(state.copyWith(isLoadingMore: true));
    
    final result = await repository.getItems(page: state.currentPage + 1);
    
    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false)),
      (newItems) => emit(PaginatedState(
        items: [...state.items, ...newItems],
        hasMore: newItems.isNotEmpty,
        currentPage: state.currentPage + 1,
      )),
    );
  }
}
```

---

## 8. Navigation

### 8.1 GoRouter Configuration

Navigation is configured using **go_router** in `lib/features/auth/presentation/router/auth_router.dart`.

#### Adding a New Route

```dart
class AuthRouter {
  static List<RouteBase> get routes => [
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider(
          create: (context) => AuthBloc(sl()),
          child: AuthWrapperPage(
            authenticatedChild: NavigationShell(child: child),
          ),
        );
      },
      routes: [
        // Add your new route here
        GoRoute(
          name: 'my-feature', // Named route for easy access
          path: '/my-feature',
          builder: (context, state) => const MyFeaturePage(),
          routes: [
            // Nested route
            GoRoute(
              name: 'my-feature-detail',
              path: ':id', // Will be /my-feature/:id
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return MyFeatureDetailPage(id: id);
              },
            ),
          ],
        ),
      ],
    ),
  ];
}
```

### 8.2 Navigation Methods

```dart
import 'package:go_router/go_router.dart';

// Navigate to a route
context.go('/my-feature');

// Navigate with path parameters
context.go('/services/facebook');

// Navigate with query parameters
context.go('/search?q=flutter');

// Navigate using named routes
context.goNamed('my-feature-detail', pathParameters: {'id': '123'});

// Navigate and pass complex data
context.goNamed('edit-area', extra: areaObject);

// Navigate back
context.pop();

// Pop with result
context.pop(true);

// Check if can pop
if (context.canPop()) {
  context.pop();
}

// Replace current route
context.pushReplacement('/login');
```

### 8.3 Bottom Navigation

The app uses a custom bottom navigation bar defined in `lib/core/navigation/main_scaffold.dart`.

#### Adding a Navigation Item

1. **Add destination** to `lib/core/navigation/navigation_destinations.dart`:

```dart
enum AppDestination {
  dashboard,
  services,
  areas,
  profile,
  notifications, // New destination
}
```

2. **Add navigation item** to `lib/core/navigation/navigation_items.dart`:

```dart
class AppNavigationItems {
  static const List<NavigationItem> destinations = [
    // ... existing items ...
    NavigationItem(
      destination: AppDestination.notifications,
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      path: '/notifications',
    ),
  ];
}
```

### 8.4 Authentication Guards

Routes are automatically protected by `AuthWrapperPage`. Unauthenticated users are redirected to login.

To bypass authentication for a route:

```dart
GoRoute(
  path: '/public-route',
  builder: (context, state) => PublicPage(),
  // This route will be outside the ShellRoute with AuthWrapper
),
```

---

## 9. API Integration

### 9.1 API Configuration

All API configuration is in `lib/core/network/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = "http://10.0.2.2:8080";
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  
  static const Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
  
  static const bool enableLogging = true;
}
```

### 9.2 Making API Calls

The `ApiClient` wrapper around Dio provides convenient methods:

```dart
class MyRemoteDataSource {
  final ApiClient _apiClient;
  
  MyRemoteDataSourceImpl(this._apiClient);
  
  // GET request
  Future<MyModel> getData() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/my-endpoint',
        queryParameters: {'page': 1, 'limit': 10},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return MyModel.fromJson(response.data!);
      }
      
      throw NetworkException('Unexpected response');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST request
  Future<MyModel> createData(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/my-endpoint',
        data: data,
      );
      
      if (response.statusCode == 201 && response.data != null) {
        return MyModel.fromJson(response.data!);
      }
      
      throw NetworkException('Failed to create');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT request
  Future<MyModel> updateData(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/v1/my-endpoint/$id',
      data: data,
    );
    return MyModel.fromJson(response.data!);
  }
  
  // DELETE request
  Future<bool> deleteData(String id) async {
    final response = await _apiClient.delete('/v1/my-endpoint/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }
  
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      switch (statusCode) {
        case 400:
          return BadRequestException(data['error'] ?? 'Bad request');
        case 401:
          return UnauthorizedException('Authentication required');
        case 404:
          return NotFoundException('Resource not found');
        case 500:
          return ServerException('Server error');
        default:
          return NetworkException('HTTP $statusCode');
      }
    }
    
    return NetworkException.fromDioError(error);
  }
}
```

### 9.3 Interceptors

#### Logging Interceptor

Automatically logs all requests/responses when `ApiConfig.enableLogging` is true.

#### Error Interceptor

Converts Dio errors to domain exceptions.

#### Retry Interceptor

Automatically retries failed requests (connection timeouts):

```dart
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  
  RetryInterceptor({required this.dio, this.maxRetries = 3});
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && _retryCount < maxRetries) {
      _retryCount++;
      final delay = pow(2, _retryCount).toInt(); // Exponential backoff
      await Future.delayed(Duration(seconds: delay));
      
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        super.onError(err, handler);
      }
    } else {
      super.onError(err, handler);
    }
  }
  
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;
  }
}
```

### 9.4 Cookie Management

The app uses `cookie_jar` for automatic cookie persistence:

```dart
final cookieJar = PersistCookieJar(
  ignoreExpires: false,
  storage: FileStorage("${supportDir.path}/cookies"),
);

_dio.interceptors.add(CookieManager(cookieJar));
```

Cookies are automatically:
- Sent with requests
- Stored after responses
- Persisted across app restarts

---

## 10. Design System

### 10.1 Color Palette

All colors are defined in `lib/core/design_system/app_colors.dart`:

```dart
// Primary colors
AppColors.primary          // #2563EB
AppColors.primaryLight     // #3B82F6
AppColors.primaryDark      // #1D4ED8

// Semantic colors
AppColors.success          // #10B981
AppColors.warning          // #F59E0B
AppColors.error            // #EF4444

// Theme-aware colors (auto-adapt to light/dark)
AppColors.getBackgroundColor(context)
AppColors.getSurfaceColor(context)
AppColors.getTextPrimaryColor(context)
AppColors.getTextSecondaryColor(context)
AppColors.getBorderColor(context)
```

#### Usage

```dart
// Direct usage
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.white),
  ),
)

// Theme-aware usage (recommended)
Container(
  color: AppColors.getSurfaceColor(context),
  child: Text(
    'Hello',
    style: TextStyle(
      color: AppColors.getTextPrimaryColor(context),
    ),
  ),
)
```

### 10.2 Typography

Text styles are defined in `lib/core/design_system/app_typography.dart`:

```dart
// Display styles (large headings)
AppTypography.displayLarge     // 32sp, w800
AppTypography.displayMedium    // 28sp, w700

// Headline styles
AppTypography.headlineLarge    // 24sp, w600
AppTypography.headlineMedium   // 20sp, w600

// Body styles
AppTypography.bodyLarge        // 16sp, w400
AppTypography.bodyMedium       // 14sp, w400

// Label styles (buttons, chips)
AppTypography.labelLarge       // 14sp, w500
AppTypography.labelMedium      // 12sp, w500
```

#### Usage

```dart
Text(
  'Welcome!',
  style: AppTypography.displayLarge.copyWith(
    color: AppColors.getTextPrimaryColor(context),
  ),
)
```

### 10.3 Spacing

Consistent spacing values in `lib/core/design_system/app_spacing.dart`:

```dart
AppSpacing.xs      // 4.0
AppSpacing.sm      // 8.0
AppSpacing.md      // 16.0
AppSpacing.lg      // 24.0
AppSpacing.xl      // 32.0
AppSpacing.xxl     // 48.0
AppSpacing.xxxl    // 64.0
```

#### Usage

```dart
Padding(
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Column(
    children: [
      Text('Title'),
      const SizedBox(height: AppSpacing.md),
      Text('Content'),
    ],
  ),
)
```

### 10.4 Creating Reusable Widgets

**Example: Custom Button**

```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
```

### 10.5 Responsive Design

#### Using LayoutBuilder

```dart
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Mobile
      if (constraints.maxWidth < 600) {
        return MobileLayout();
      }
      
      // Tablet
      if (constraints.maxWidth < 900) {
        return TabletLayout();
      }
      
      // Desktop
      return DesktopLayout();
    },
  );
}
```

#### Adaptive Grid

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
    childAspectRatio: 0.8,
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
  ),
  itemBuilder: (context, index) => ItemCard(item: items[index]),
)
```

---

## 11. Best Practices

### 11.1 Code Organization

#### File Naming

```
✅ DO
user_repository.dart
login_page.dart
auth_text_field.dart
services_list_bloc.dart

❌ DON'T
UserRepository.dart
Login_Page.dart
authTextField.dart
serviceslistbloc.dart
```

#### Imports Order

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:convert';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Package imports
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. Relative imports
import '../../domain/entities/user.dart';
import '../widgets/user_card.dart';
```

### 11.2 Performance

#### Const Constructors

```dart
// ✅ DO: Use const when possible
const Padding(
  padding: EdgeInsets.all(16.0),
  child: Text('Hello'),
)

// ❌ DON'T: Create new instances unnecessarily
Padding(
  padding: EdgeInsets.all(16.0),
  child: Text('Hello'),
)
```

#### Build Method Optimization

```dart
// ✅ DO: Extract complex widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildContent(),
        _buildFooter(),
      ],
    );
  }
  
  Widget _buildHeader() => const HeaderWidget();
}

// ❌ DON'T: Inline everything
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          // 50 lines of complex UI...
        ),
        // More complex inline widgets...
      ],
    );
  }
}
```

### 11.3 Error Handling

#### Always Handle Errors

```dart
// ✅ DO
try {
  final result = await repository.getData();
  result.fold(
    (failure) => _handleError(failure),
    (data) => _handleSuccess(data),
  );
} catch (e) {
  print('Unexpected error: $e');
  _showGenericError();
}

// ❌ DON'T: Ignore errors
final result = await repository.getData();
final data = result.getOrElse(() => []); // Silent failure
```

#### User-Friendly Error Messages

```dart
String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case NetworkFailure _:
      return 'No internet connection. Please check your network.';
    case UnauthorizedFailure _:
      return 'Session expired. Please log in again.';
    case ServerFailure _:
      return 'Server is temporarily unavailable. Please try again later.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
```

### 11.4 Documentation

#### Comment Complex Logic

```dart
/// Calculates the total price with discounts and taxes.
/// 
/// [basePrice] The original price before discounts
/// [discountPercent] Discount percentage (0-100)
/// [taxRate] Tax rate as decimal (e.g., 0.20 for 20%)
/// 
/// Returns the final price rounded to 2 decimal places
/// 
/// Example:
/// ```dart
/// final price = calculateFinalPrice(100.0, 10, 0.20);
/// print(price); // 108.00
/// ```
double calculateFinalPrice(
  double basePrice,
  double discountPercent,
  double taxRate,
) {
  // Apply discount
  final discountedPrice = basePrice * (1 - discountPercent / 100);
  
  // Add tax
  final finalPrice = discountedPrice * (1 + taxRate);
  
  // Round to 2 decimals
  return (finalPrice * 100).round() / 100;
}
```

### 11.5 Testing Guidelines

#### Test Structure (Future Implementation)

```dart
group('LoginCubit', () {
  late LoginCubit cubit;
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    cubit = LoginCubit(mockRepository);
  });
  
  tearDown(() {
    cubit.close();
  });
  
  test('initial state is LoginInitial', () {
    expect(cubit.state, isA<LoginInitial>());
  });
  
  blocTest<LoginCubit, LoginState>(
    'emits [LoginLoading, LoginSuccess] when login succeeds',
    build: () {
      when(() => mockRepository.login(any(), any()))
          .thenAnswer((_) async => Right(mockUser));
      return cubit;
    },
    act: (cubit) => cubit.login('test@example.com', 'password'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginSuccess>(),
    ],
  );
});
```

---

## 12. Troubleshooting

### 12.1 Common Issues

#### "Can't find dependency" Error

**Problem**: `GetIt` can't find a registered dependency

**Solution**:
```dart
// Check that dependency is registered in injection.dart
sl.registerLazySingleton<MyRepository>(
  () => MyRepositoryImpl(sl()),
);

// Ensure initCoreDependencies() is called in main.dart
await initCoreDependencies();

// Use correct type when retrieving
final repo = sl<MyRepository>(); // ✅
final repo = sl<MyRepositoryImpl>(); // ❌ (unless registered as impl)
```

#### Navigation Not Working

**Problem**: `context.go()` doesn't navigate

**Solution**:
```dart
// Ensure route is registered in auth_router.dart
GoRoute(
  path: '/my-route',
  builder: (context, state) => MyPage(),
)

// Use correct path (leading slash required)
context.go('/my-route'); // ✅
context.go('my-route'); // ❌

// Check that you're inside GoRouter context
// If using a Dialog/BottomSheet, use Navigator context instead
Navigator.of(context, rootNavigator: true).pop();
```

#### BLoC State Not Updating

**Problem**: UI doesn't rebuild when state changes

**Solution**:
```dart
// 1. Ensure state implements Equatable properly
class MyState extends Equatable {
  final List<Item> items;
  const MyState(this.items);
  
  @override
  List<Object?> get props => [items]; // ✅ Include all properties
}

// 2. Don't mutate state, create new instances
final newItems = [...state.items, newItem]; // ✅
emit(MyState(newItems));

state.items.add(newItem); // ❌ Mutation
emit(state); // ❌ Same instance

// 3. Use correct builder
BlocBuilder<MyBloc, MyState>(...) // ✅
Builder(...) // ❌ Won't listen to BLoC
```

#### API Calls Failing

**Problem**: All API calls return errors

**Solution**:
```dart
// 1. Check base URL for your platform
// Android emulator: http://10.0.2.2:8080
// iOS simulator: http://localhost:8080
// Physical device: http://<your-ip>:8080

// 2. Verify backend is running
// curl http://localhost:8080/about.json

// 3. Check Android network permissions
// In android/app/src/main/AndroidManifest.xml:
<uses-permission android:name="android.permission.INTERNET" />

// 4. For HTTPS, check certificate
// In Android: android:usesCleartextTraffic="true" (dev only)
```

#### Build Errors After Pulling Changes

```bash
# 1. Clean build
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Rebuild
flutter run
```

### 12.2 Debugging Tips

#### Enable Verbose Logging

```dart
// In api_config.dart
static const bool enableLogging = true;

// In BLoC
@override
void onChange(Change<MyState> change) {
  super.onChange(change);
  print('State changed: ${change.currentState} -> ${change.nextState}');
}
```

#### Inspect BLoC States

```dart
// Use BlocObserver
class MyBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}

// Register in main.dart
void main() {
  Bloc.observer = MyBlocObserver();
  runApp(MyApp());
}
```

#### Debug Navigation

```dart
// Log all route changes
final router = GoRouter(
  // ...
  observers: [MyNavigatorObserver()],
);

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    print('Pushed: ${route.settings.name}');
  }
}
```

---

## Appendix

### A. Useful Commands

```bash
# Run app
flutter run

# Hot reload
r

# Hot restart
R

# Run on specific device
flutter devices
flutter run -d <device-id>

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Analyze code
flutter analyze

# Format code
dart format lib/

# Check outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### B. Recommended VSCode Extensions

- Flutter
- Dart
- Bloc
- Error Lens
- Better Comments
- TODO Tree
- Git Lens

### C. Project Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [BLoC Library](https://bloclibrary.dev/)
- [Go Router](https://pub.dev/packages/go_router)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [GetIt DI](https://pub.dev/packages/get_it)

---

**Document Version**: 1.0  
**Last Updated**: 4 October 2025  
**Maintained By**: Laurent Aliu (laurent.aliu@epitech.eu), Enzo Gallini (enzo.gallini@epitech.eu)

For questions or suggestions, please create an issue in the repository or contact the development team.