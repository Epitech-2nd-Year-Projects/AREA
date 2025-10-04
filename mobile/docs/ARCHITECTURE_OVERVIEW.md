# AREA Mobile - Architecture Overview

## Document Information

**Version**: 1.0  
**Last Updated**: 4 October 2025
**Authors**: Laurent Aliu (laurent.aliu@epitech.eu), Enzo Gallini (enzo.gallini@epitech.eu)
**Target Audience**: Software Architects, Senior Developers, Tech Leads

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architectural Principles](#2-architectural-principles)
3. [High-Level Architecture](#3-high-level-architecture)
4. [Layer Architecture Deep Dive](#4-layer-architecture-deep-dive)
5. [Data Flow & Communication](#5-data-flow--communication)
6. [State Management Architecture](#6-state-management-architecture)
7. [Navigation Architecture](#7-navigation-architecture)
8. [Dependency Management](#8-dependency-management)
9. [Feature Modules Architecture](#9-feature-modules-architecture)
10. [Cross-Cutting Concerns](#10-cross-cutting-concerns)
11. [Design Patterns & Best Practices](#11-design-patterns--best-practices)
12. [Architecture Decision Records](#12-architecture-decision-records)

---

## 1. Executive Summary

### 1.1 Overview

AREA Mobile is a Flutter-based automation platform client that follows **Clean Architecture** principles combined with **BLoC pattern** for state management. The architecture is designed to be:

- **Maintainable**: Clear separation of concerns
- **Testable**: Each layer can be tested independently
- **Scalable**: Easy to add new features without breaking existing code
- **Flexible**: Business logic independent of UI and frameworks

### 1.2 Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| **Clean Architecture** | Separation of concerns, testability, maintainability |
| **BLoC/Cubit Pattern** | Predictable state management, separation of business logic from UI |
| **Repository Pattern** | Abstract data sources, enable testing with mocks |
| **Use Case Pattern** | Single responsibility, reusable business operations |
| **Value Objects** | Domain validation, type safety |
| **Either Monad** | Functional error handling without exceptions in business logic |
| **Dependency Injection (GetIt)** | Loose coupling, testability, configuration management |
| **Go Router** | Declarative routing, deep linking support, type-safe navigation |

### 1.3 Technology Stack

```
┌─────────────────────────────────────────────────┐
│              Flutter Framework 3.x              │
├─────────────────────────────────────────────────┤
│  UI Layer    │ flutter_bloc │ go_router        │
├─────────────────────────────────────────────────┤
│  Domain      │ dartz │ equatable               │
├─────────────────────────────────────────────────┤
│  Data Layer  │ dio │ shared_preferences         │
│              │ flutter_secure_storage            │
├─────────────────────────────────────────────────┤
│  DI          │ get_it                           │
└─────────────────────────────────────────────────┘
```

---

## 2. Architectural Principles

### 2.1 SOLID Principles

#### Single Responsibility Principle (SRP)
Each class has one reason to change:
- **Use Cases**: One business operation per class
- **Repositories**: One data source concern per interface
- **BLoCs**: One feature state management per BLoC
- **Widgets**: One UI concern per widget

#### Open/Closed Principle (OCP)
Open for extension, closed for modification:
- Repository interfaces allow new implementations without changing consumers
- Abstract data sources enable adding new persistence mechanisms
- BLoC events can be extended without modifying existing handlers

#### Liskov Substitution Principle (LSP)
Implementations can replace their interfaces:
```dart
// Any AuthRepository implementation can replace the interface
AuthRepository repo = AuthRepositoryImpl(dataSource);
AuthRepository mockRepo = MockAuthRepository(); // Testing
```

#### Interface Segregation Principle (ISP)
Clients shouldn't depend on interfaces they don't use:
- Separate remote and local data source interfaces
- Feature-specific repository interfaces
- Granular use cases instead of monolithic services

#### Dependency Inversion Principle (DIP)
Depend on abstractions, not concretions:
```dart
// ✅ Depends on abstraction
class LoginCubit {
  final AuthRepository _repository; // Interface
}

// ❌ Depends on concrete implementation
class LoginCubit {
  final AuthRepositoryImpl _repository; // Implementation
}
```

### 2.2 Clean Architecture Principles

#### Independence of Frameworks
Business logic doesn't depend on Flutter:
- Domain layer uses pure Dart
- No Flutter imports in domain entities, use cases, or repositories
- Framework can be swapped (theoretically)

#### Testability
Each layer can be tested independently:
- Domain logic tested without UI
- Data layer tested without backend
- Presentation tested with mock repositories

#### Independence of UI
Business logic remains unchanged when UI changes:
- Switching from Material to Cupertino doesn't affect domain
- Responsive layouts don't impact business rules

#### Independence of Database
Data sources are abstracted:
```dart
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
}

// Can be implemented with:
// - SharedPreferences
// - SQLite
// - Hive
// - Any other storage mechanism
```

#### Independence of External Agencies
Business logic doesn't know about external services:
- API structure changes don't affect domain
- Third-party SDK changes isolated to data layer

---

## 3. High-Level Architecture

### 3.1 Layered Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │    Pages     │  │   Widgets    │  │  BLoC/Cubit  │          │
│  │              │  │              │  │              │          │
│  │ - LoginPage  │  │ - AuthButton │  │ - AuthBloc   │          │
│  │ - AreasPage  │  │ - AreaCard   │  │ - AreasCubit │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                             │                                    │
│                             ↓                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Calls Use Cases
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        DOMAIN LAYER                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Entities   │  │  Use Cases   │  │ Repositories │          │
│  │              │  │              │  │ (Interfaces) │          │
│  │ - User       │  │ - LoginUser  │  │ - AuthRepo   │          │
│  │ - Area       │  │ - GetAreas   │  │ - AreasRepo  │          │
│  │ - Service    │  │ - Subscribe  │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                             │                                    │
│                             ↓                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Interface Implementation
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Models     │  │ Data Sources │  │ Repositories │          │
│  │   (DTOs)     │  │              │  │    (Impl)    │          │
│  │              │  │ - Remote     │  │              │          │
│  │ - UserModel  │  │ - Local      │  │ - AuthRepoImpl│         │
│  │ - AreaModel  │  │              │  │ - AreasRepoImpl│        │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                             │                                    │
│                             ↓                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ↓                   ↓
          ┌──────────────┐    ┌──────────────┐
          │   REST API   │    │Local Storage │
          │   (Backend)  │    │              │
          └──────────────┘    └──────────────┘
```

### 3.2 Dependency Direction

The **Dependency Rule**: Dependencies point inward (from outer to inner layers).

```
Presentation ──→ Domain ←── Data
     ↓                          ↓
     └──────── Core ←───────────┘
```

**Key Points**:
- Presentation depends on Domain (interfaces)
- Data depends on Domain (implements interfaces)
- Domain depends on nothing (pure business logic)
- Core utilities can be used by any layer

### 3.3 Module Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Root widget
│
├── core/                        # Shared infrastructure
│   ├── design_system/           # UI constants
│   ├── di/                      # Dependency injection
│   ├── error/                   # Error types
│   ├── navigation/              # Routing
│   ├── network/                 # HTTP client
│   └── storage/                 # Persistence
│
└── features/                    # Business features
    ├── auth/                    # Authentication
    │   ├── data/
    │   │   ├── datasources/
    │   │   ├── models/
    │   │   └── repositories/
    │   ├── domain/
    │   │   ├── entities/
    │   │   ├── repositories/
    │   │   ├── use_cases/
    │   │   └── value_objects/
    │   └── presentation/
    │       ├── blocs/
    │       ├── pages/
    │       └── widgets/
    │
    ├── services/                # Service management
    └── areas/                   # Automation (AREA)
```

---

## 4. Layer Architecture Deep Dive

### 4.1 Presentation Layer

#### 4.1.1 Responsibilities

1. **Display UI** to users
2. **Capture user input** (taps, text entry, gestures)
3. **Manage UI state** (loading, error, success states)
4. **Navigate** between screens
5. **Display feedback** (snackbars, dialogs)

#### 4.1.2 Components

**Pages** (Full Screens)
```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(sl()),
      child: const _LoginPageContent(),
    );
  }
}
```
- One page per route
- Provides BLoC/Cubit to widget tree
- Handles BLoC listeners (navigation, snackbars)

**Widgets** (Reusable Components)
```dart
class AuthTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  // ... more properties
}
```
- Reusable UI components
- No business logic
- Configured via props/parameters

**BLoC/Cubit** (State Management)
```dart
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;
  late final LoginUser _loginUser;
  
  LoginCubit(this._repository) : super(LoginInitial()) {
    _loginUser = LoginUser(_repository);
  }
  
  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    
    final emailVO = Email(email);
    final passwordVO = Password(password);
    final result = await _loginUser(emailVO, passwordVO);
    
    result.fold(
      (failure) => emit(LoginError(failure.message)),
      (user) => emit(LoginSuccess(user)),
    );
  }
}
```

#### 4.1.3 State Management Pattern

**State Classes**
```dart
abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final User user;
  const LoginSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

class LoginError extends LoginState {
  final String message;
  const LoginError(this.message);
  @override
  List<Object?> get props => [message];
}
```

**Key Principles**:
- Immutable state classes
- Equatable for comparison
- Explicit state transitions
- No business logic in states

#### 4.1.4 UI Composition

```
LoginPage (BlocProvider)
    │
    ├─ Scaffold
    │   │
    │   ├─ AppBar
    │   │
    │   └─ Body
    │       │
    │       ├─ BlocListener (side effects)
    │       │   │
    │       │   └─ BlocBuilder (UI rendering)
    │       │       │
    │       │       └─ LoginForm
    │       │           │
    │       │           ├─ AuthTextField (email)
    │       │           ├─ AuthTextField (password)
    │       │           └─ AuthButton (submit)
    │       │
    │       └─ OAuthButtons
```

#### 4.1.5 Rules & Constraints

✅ **DO**:
- Keep widgets simple and focused
- Use BLoC for feature state
- Use StatefulWidget for local UI state (e.g., text field focus)
- Handle errors gracefully with user-friendly messages
- Extract complex widgets into separate classes

❌ **DON'T**:
- Put business logic in widgets
- Access repositories directly from UI
- Use global state (singletons, static variables)
- Perform async operations in build methods
- Mutate state objects

---

### 4.2 Domain Layer

#### 4.2.1 Responsibilities

1. **Define business entities** (core data structures)
2. **Encode business rules** (validation, calculations)
3. **Define contracts** (repository interfaces)
4. **Implement use cases** (business operations)
5. **Define domain exceptions** (business-specific errors)

#### 4.2.2 Components

**Entities** (Core Business Objects)
```dart
class Area extends Equatable {
  final String id;
  final String userId;
  final String name;
  final bool isActive;
  final String actionName;
  final String reactionName;
  
  const Area({
    required this.id,
    required this.userId,
    required this.name,
    required this.isActive,
    required this.actionName,
    required this.reactionName,
  });
  
  Area copyWith({
    String? name,
    bool? isActive,
    // ...
  }) {
    return Area(
      id: id,
      userId: userId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      actionName: actionName,
      reactionName: reactionName,
    );
  }
  
  @override
  List<Object?> get props => [id, userId, name, isActive, actionName, reactionName];
}
```

**Characteristics**:
- Immutable (use `final` fields)
- Equatable for value comparison
- No dependencies on other layers
- Pure Dart (no Flutter imports)
- Business-focused properties only

**Repository Interfaces** (Data Contracts)
```dart
abstract class AreaRepository {
  Future<List<Area>> getAreas();
  Future<Area> createArea(Area area);
  Future<Area> updateArea(Area area);
  Future<void> deleteArea(String areaId);
}
```

**Key Points**:
- Abstract contracts, no implementation
- Return types use domain entities
- Async operations return Future
- Error handling via Either monad (when used)

**Use Cases** (Business Operations)
```dart
class GetAreas {
  final AreaRepository _repository;
  
  GetAreas(this._repository);
  
  Future<List<Area>> call() async {
    return await _repository.getAreas();
  }
}
```

**Architecture**:
- One use case = one business operation
- Single responsibility principle
- Depends only on repository interface
- Called from presentation layer (BLoC/Cubit)

**Value Objects** (Domain Types with Validation)
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
    return RegExp(r'^[\w.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$')
        .hasMatch(email);
  }
  
  @override
  String toString() => value;
}
```

**Benefits**:
- Encapsulates validation logic
- Type safety (can't pass invalid email)
- Self-documenting code
- Reusable across the domain

**Domain Exceptions**
```dart
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException() 
      : super('Invalid email or password.');
}

class UserAlreadyExistsException extends AuthException {
  UserAlreadyExistsException()
      : super('A user with this email already exists.');
}
```

#### 4.2.3 Functional Error Handling

**Either Monad Pattern**
```dart
import 'package:dartz/dartz.dart';

// Repository method signature
Future<Either<Failure, User>> login(Email email, Password password);

// Usage in Use Case
class LoginUser {
  final AuthRepository _repository;
  
  LoginUser(this._repository);
  
  Future<Either<Failure, User>> call(Email email, Password password) async {
    return await _repository.login(email, password);
  }
}

// Usage in BLoC
final result = await _loginUser(email, password);

result.fold(
  (failure) {
    // Left side = error
    emit(LoginError(failure.message));
  },
  (user) {
    // Right side = success
    emit(LoginSuccess(user));
  },
);
```

**Failure Hierarchy**
```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  
  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
```

#### 4.2.4 Domain Layer Rules

✅ **DO**:
- Keep entities simple and focused
- Validate data at domain boundaries (value objects)
- Use interfaces for all external dependencies
- Return domain entities from repositories
- Keep use cases single-purpose

❌ **DON'T**:
- Import Flutter packages
- Import data layer packages
- Include platform-specific code
- Perform I/O operations directly
- Depend on concrete implementations

---

### 4.3 Data Layer

#### 4.3.1 Responsibilities

1. **Implement repository interfaces**
2. **Communicate with external data sources** (API, database)
3. **Transform data** between models and entities
4. **Cache data** when appropriate
5. **Handle data-specific errors** (network, parsing)

#### 4.3.2 Components

**Models (Data Transfer Objects)**
```dart
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    this.status,
    this.createdAt,
    this.lastLoginAt,
  });
  
  final String? status;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  
  // Serialization
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
    };
  }
  
  // Conversion to domain entity
  User toDomain() {
    return User(id: id, email: email);
  }
}
```

**Key Characteristics**:
- Extends domain entity (inherits core properties)
- Additional fields for persistence/API response
- Serialization methods (fromJson, toJson)
- Conversion method to domain entity
- Can include nullable fields not in domain

**Data Sources**

**Remote Data Source** (API Communication)
```dart
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<RegisterResponseModel> register(String email, String password);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  
  AuthRemoteDataSourceImpl(this._apiClient);
  
  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return AuthResponseModel.fromJson(response.data!);
      }
      
      throw NetworkException('Unexpected response');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      switch (statusCode) {
        case 401:
          return UnauthorizedException('Invalid credentials');
        case 403:
          return AccountNotVerifiedException();
        default:
          return NetworkException('HTTP $statusCode');
      }
    }
    return NetworkException.fromDioError(error);
  }
}
```

**Local Data Source** (Persistence)
```dart
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<bool> hasAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalPrefsManager _prefs;
  
  AuthLocalDataSourceImpl(this._prefs);
  
  @override
  Future<void> cacheUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.writeString(StorageKeys.userProfile, userJson);
  }
  
  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = _prefs.readString(StorageKeys.userProfile);
      if (userJson == null) return null;
      
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<void> clearCache() async {
    await _prefs.delete(StorageKeys.userProfile);
  }
  
  @override
  Future<bool> hasAuthData() async {
    final user = await getCachedUser();
    return user != null;
  }
}
```

**Repository Implementation**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);
  
  @override
  Future<Either<Failure, User>> login(
    Email email,
    Password password,
  ) async {
    try {
      // Call remote data source
      final response = await _remoteDataSource.login(
        email.value,
        password.value,
      );
      
      // Convert model to entity
      final user = response.user.toDomain();
      
      // Cache user locally
      await _localDataSource.cacheUser(response.user);
      
      // Return success
      return Right(user);
    } on InvalidCredentialsException {
      return const Left(UnauthorizedFailure('Invalid credentials'));
    } on AccountNotVerifiedException {
      return const Left(UnauthorizedFailure('Account not verified'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Try to get from remote first
      final userModel = await _remoteDataSource.getCurrentUser();
      final user = userModel.toDomain();
      
      // Update cache
      await _localDataSource.cacheUser(userModel);
      
      return Right(user);
    } on UnauthorizedException {
      // Clear cache on auth failure
      await _localDataSource.clearCache();
      return const Left(UnauthorizedFailure('Not authenticated'));
    } catch (e) {
      // Fallback to cached data
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toDomain());
      }
      return const Left(UnauthorizedFailure('Not authenticated'));
    }
  }
}
```

#### 4.3.3 Data Flow Pattern

```
Repository (Interface)
    │
    ├─→ Remote Data Source
    │     │
    │     ├─ API Client (Dio)
    │     └─ Response Model
    │           │
    │           └─→ Domain Entity (via toDomain())
    │
    ├─→ Local Data Source
    │     │
    │     ├─ Local Storage (SharedPreferences)
    │     └─ Cached Model
    │           │
    │           └─→ Domain Entity (via toDomain())
    │
    └─→ Return Either<Failure, Entity>
```

#### 4.3.4 Caching Strategy

**Cache-First Strategy** (Offline-first)
```dart
@override
Future<Either<Failure, List<Item>>> getItems() async {
  try {
    // 1. Return cached data immediately
    final cachedItems = await _localDataSource.getCachedItems();
    if (cachedItems.isNotEmpty) {
      // Refresh in background
      _refreshItems();
      return Right(cachedItems.map((m) => m.toDomain()).toList());
    }
    
    // 2. Fetch from network if no cache
    final remoteItems = await _remoteDataSource.getItems();
    await _localDataSource.cacheItems(remoteItems);
    
    return Right(remoteItems.map((m) => m.toDomain()).toList());
  } catch (e) {
    return Left(NetworkFailure(e.toString()));
  }
}
```

**Network-First Strategy** (Always fresh)
```dart
@override
Future<Either<Failure, List<Item>>> getItems() async {
  try {
    // 1. Try network first
    final remoteItems = await _remoteDataSource.getItems();
    await _localDataSource.cacheItems(remoteItems);
    
    return Right(remoteItems.map((m) => m.toDomain()).toList());
  } on NetworkException {
    // 2. Fallback to cache on network error
    final cachedItems = await _localDataSource.getCachedItems();
    if (cachedItems.isNotEmpty) {
      return Right(cachedItems.map((m) => m.toDomain()).toList());
    }
    
    return const Left(NetworkFailure('No network and no cache'));
  }
}
```

#### 4.3.5 Data Layer Rules

✅ **DO**:
- Implement all repository interfaces
- Convert models to entities before returning
- Handle all exceptions and convert to Failures
- Cache data when appropriate
- Use data sources for all I/O operations

❌ **DON'T**:
- Return models directly to presentation layer
- Leak data source exceptions to domain
- Put business logic in repositories
- Access multiple data sources from presentation
- Make repositories stateful

---

## 5. Data Flow & Communication

### 5.1 Complete Request Flow

#### User Login Flow (End-to-End)

```
1. USER INTERACTION
   │
   └─→ User taps "Login" button on LoginPage
       │
       └─→ Form validates input
           │
           └─→ Calls LoginCubit.login(email, password)

2. PRESENTATION LAYER
   │
   ├─→ LoginCubit receives call
   │   │
   │   ├─ Creates Email value object (validates)
   │   ├─ Creates Password value object (validates)
   │   ├─ Emits LoginLoading state
   │   │
   │   └─→ Calls LoginUser use case
   │
   └─→ UI rebuilds (shows loading spinner)

3. DOMAIN LAYER
   │
   └─→ LoginUser use case
       │
       ├─ Receives Email and Password value objects
       │
       └─→ Calls AuthRepository.login(email, password)

4. DATA LAYER
   │
   └─→ AuthRepositoryImpl
       │
       ├─→ Calls AuthRemoteDataSource.login()
       │   │
       │   ├─→ ApiClient sends HTTP POST to /v1/auth/login
       │   │   │
       │   │   ├─ Interceptors process request
       │   │   │  (logging, cookies, auth headers)
       │   │   │
       │   │   └─→ Backend API receives request
       │   │
       │   ├─← Backend returns response
       │   │   │
       │   │   └─→ Interceptors process response
       │   │
       │   ├─ Parses JSON to AuthResponseModel
       │   │
       │   └─→ Returns AuthResponseModel
       │
       ├─ Extracts UserModel from response
       │
       ├─→ Caches user with AuthLocalDataSource
       │
       ├─ Converts UserModel to User entity (toDomain())
       │
       └─→ Returns Either<Failure, User>

5. DOMAIN LAYER (Return)
   │
   └─→ LoginUser use case returns Either<Failure, User>

6. PRESENTATION LAYER (Return)
   │
   └─→ LoginCubit receives result
       │
       ├─ Calls result.fold()
       │  │
       │  ├─ Left (Failure): Emits LoginError(message)
       │  │
       │  └─ Right (User): Emits LoginSuccess(user)
       │
       └─→ UI rebuilds based on new state

7. UI REACTION
   │
   ├─ BlocListener detects LoginSuccess
   │  │
   │  └─→ Navigates to /dashboard
   │
   └─ BlocBuilder renders success UI
```

### 5.2 Event Flow Diagram

```
┌─────────────┐
│     UI      │ User taps button
│   (Page)    │─────────────────┐
└─────────────┘                 │
                                ↓
                      ┌──────────────────┐
                      │  BLoC/Cubit      │
                      │  (State Manager) │
                      └──────────────────┘
                                │
                                │ emit(Loading)
                                ↓
┌─────────────┐       ┌──────────────────┐
│     UI      │←──────│   LoadingState   │
│  (Rebuild)  │       └──────────────────┘
└─────────────┘
                                │
                                │ call UseCase
                                ↓
                      ┌──────────────────┐
                      │    Use Case      │
                      │  (Business Op)   │
                      └──────────────────┘
                                │
                                │ call Repository
                                ↓
                      ┌──────────────────┐
                      │   Repository     │
                      │   (Interface)    │
                      └──────────────────┘
                                │
                                │ implemented by
                                ↓
                      ┌──────────────────┐
                      │  Repository Impl │
                      │   (Data Layer)   │
                      └──────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ↓                       ↓
          ┌──────────────┐        ┌──────────────┐
          │ Remote Data  │        │ Local Data   │
          │   Source     │        │   Source     │
          └──────────────┘        └──────────────┘
                    │                       │
                    ↓                       ↓
          ┌──────────────┐        ┌──────────────┐
          │   API Call   │        │  Storage I/O │
          └──────────────┘        └──────────────┘
                    │                       │
                    └───────────┬───────────┘
                                │
                                │ return Either<Failure, Entity>
                                ↓
                      ┌──────────────────┐
                      │  Repository Impl │
                      └──────────────────┘
                                │
                                │ return Either
                                ↓
                      ┌──────────────────┐
                      │    Use Case      │
                      └──────────────────┘
                                │
                                │ return Either
                                ↓
                      ┌──────────────────┐
                      │  BLoC/Cubit      │
                      └──────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ↓                       ↓
          ┌──────────────┐        ┌──────────────┐
          │ emit(Error)  │        │emit(Success) │
          └──────────────┘        └──────────────┘
                    │                       │
                    └───────────┬───────────┘
                                │
                                ↓
┌─────────────┐       ┌──────────────────┐
│     UI      │←──────│   New State      │
│  (Rebuild)  │       └──────────────────┘
└─────────────┘
```

### 5.3 Cross-Feature Communication

Features communicate through **shared domain contracts**, not direct coupling:

```
Feature A (Areas)
    │
    └─→ Needs to know if service is subscribed
        │
        └─→ Calls ServicesRepository.getSubscription(serviceId)
            │
            └─→ ServicesRepository (shared interface)
                │
                └─→ Feature B (Services) implements

Result: Feature A doesn't depend on Feature B implementation
```

**Example: AreaFormCubit uses ServicesRepository**
```dart
class AreaFormCubit extends Cubit<AreaFormState> {
  late final GetSubscriptionForService _getSubscription;
  
  AreaFormCubit(
    AreaRepository areaRepository,
    ServicesRepository servicesRepository, // Different feature!
  ) : super(AreaFormInitial()) {
    _getSubscription = GetSubscriptionForService(servicesRepository);
  }
  
  Future<bool> checkSubscriptionActive(String providerId) async {
    final either = await _getSubscription(providerId);
    return either.fold(
      (_) => false,
      (sub) => sub?.isActive == true,
    );
  }
}
```

---

## 6. State Management Architecture

### 6.1 BLoC Pattern Deep Dive

#### 6.1.1 BLoC Architecture

```
┌──────────────────────────────────────────────────────┐
│                      BLoC                             │
│                                                       │
│  ┌─────────────────────────────────────────────┐    │
│  │              EVENTS (Input)                  │    │
│  │  - LoadData                                  │    │
│  │  - RefreshData                               │    │
│  │  - FilterData                                │    │
│  └─────────────────────────────────────────────┘    │
│                        │                              │
│                        ↓                              │
│  ┌─────────────────────────────────────────────┐    │
│  │         EVENT HANDLERS (Logic)               │    │
│  │  - Calls use cases                           │    │
│  │  - Transforms data                           │    │
│  │  - Handles errors                            │    │
│  └─────────────────────────────────────────────┘    │
│                        │                              │
│                        ↓                              │
│  ┌─────────────────────────────────────────────┐    │
│  │              STATES (Output)                 │    │
│  │  - Initial                                   │    │
│  │  - Loading                                   │    │
│  │  - Loaded(data)                              │    │
│  │  - Error(message)                            │    │
│  └─────────────────────────────────────────────┘    │
│                                                       │
└──────────────────────────────────────────────────────┘
                        │
                        ↓
                  ┌──────────┐
                  │    UI    │
                  └──────────┘
```

#### 6.1.2 Cubit vs BLoC Decision Matrix

| Criterion | Use Cubit | Use BLoC |
|-----------|-----------|----------|
| **Complexity** | Simple state changes | Complex state transitions |
| **Event History** | Not needed | Need to replay/log events |
| **External Events** | Direct method calls | Events from multiple sources |
| **Testability** | Easier (method-based) | More verbose but structured |
| **Boilerplate** | Less code | More code (events + handlers) |

**Project Convention**: We use **Cubit by default** for simplicity unless BLoC's features are needed.

#### 6.1.3 State Design Patterns

**Loading Pattern**
```dart
abstract class MyFeatureState extends Equatable {
  const MyFeatureState();
}

class MyFeatureInitial extends MyFeatureState {
  @override
  List<Object?> get props => [];
}

class MyFeatureLoading extends MyFeatureState {
  @override
  List<Object?> get props => [];
}

class MyFeatureLoaded extends MyFeatureState {
  final List<Item> items;
  
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
```

**Composite Pattern** (Multiple Data)
```dart
class DashboardState extends Equatable {
  final bool isLoadingAreas;
  final bool isLoadingServices;
  final List<Area>? areas;
  final List<Service>? services;
  final String? areasError;
  final String? servicesError;
  
  const DashboardState({
    this.isLoadingAreas = false,
    this.isLoadingServices = false,
    this.areas,
    this.services,
    this.areasError,
    this.servicesError,
  });
  
  bool get isLoading => isLoadingAreas || isLoadingServices;
  bool get hasError => areasError != null || servicesError != null;
  bool get isLoaded => areas != null && services != null;
  
  DashboardState copyWith({
    bool? isLoadingAreas,
    bool? isLoadingServices,
    List<Area>? areas,
    List<Service>? services,
    String? areasError,
    String? servicesError,
  }) {
    return DashboardState(
      isLoadingAreas: isLoadingAreas ?? this.isLoadingAreas,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      areas: areas ?? this.areas,
      services: services ?? this.services,
      areasError: areasError ?? this.areasError,
      servicesError: servicesError ?? this.servicesError,
    );
  }
  
  @override
  List<Object?> get props => [
    isLoadingAreas,
    isLoadingServices,
    areas,
    services,
    areasError,
    servicesError,
  ];
}
```

### 6.2 State Lifecycle

```
User Action
    │
    ↓
Method Called on Cubit
    │
    ↓
emit(LoadingState)
    │
    ├─→ UI receives state
    │   └─→ Rebuilds with loading indicator
    │
    ↓
Call Use Case
    │
    ├─→ Wait for result
    │
    ↓
Result received
    │
    ├─ Success? ─→ emit(SuccessState(data))
    │               │
    │               └─→ UI receives state
    │                   └─→ Rebuilds with data
    │
    └─ Failure? ─→ emit(ErrorState(message))
                    │
                    └─→ UI receives state
                        └─→ Rebuilds with error
```

### 6.3 BLoC Communication Patterns

#### 6.3.1 Parent-Child Communication (Props)
```dart
// Parent passes data down
BlocProvider(
  create: (_) => ChildCubit(initialData: parentData),
  child: ChildWidget(),
)

// Child uses data from constructor
class ChildCubit extends Cubit<ChildState> {
  ChildCubit({required this.initialData}) : super(ChildInitial());
  final Data initialData;
}
```

#### 6.3.2 Sibling Communication (Shared Repository)
```dart
// Both cubits depend on same repository
class CubitA extends Cubit<StateA> {
  final SharedRepository _repo;
  CubitA(this._repo) : super(InitialA());
}

class CubitB extends Cubit<StateB> {
  final SharedRepository _repo;
  CubitB(this._repo) : super(InitialB());
}

// Repository notifies changes
class SharedRepository {
  final _streamController = StreamController<Data>();
  Stream<Data> get dataStream => _streamController.stream;
  
  Future<void> updateData(Data data) async {
    await _dataSource.update(data);
    _streamController.add(data);
  }
}
```

#### 6.3.3 Global State (Avoid when possible)
```dart
// Only for truly global state (user session, theme, etc.)
class AppBloc extends Bloc<AppEvent, AppState> {
  // Provided at root level
}

// Access from any widget
context.read<AppBloc>().add(AppEvent());
```

---

## 7. Navigation Architecture

### 7.1 Go Router Structure

```
GoRouter
│
├─ ShellRoute (Authenticated Shell)
│  │
│  ├─ Builder: AuthWrapperPage
│  │           │
│  │           ├─ Checks authentication
│  │           └─ Provides NavigationShell (bottom nav)
│  │
│  └─ Routes:
│     │
│     ├─ /dashboard      → DashboardPage
│     │
│     ├─ /services       → ServicesListPage
│     │  └─ /:serviceId  → ServiceDetailsPage
│     │
│     ├─ /areas          → AreasPage
│     │  ├─ /new         → AreaFormPage (create)
│     │  └─ /edit        → AreaFormPage (edit)
│     │
│     └─ /profile        → ProfilePage
│
├─ /login                → LoginPage (no auth required)
│
├─ /register             → RegisterPage (no auth required)
│
├─ /verify-email         → EmailVerificationPage
│
├─ /oauth/callback/:provider → OAuthCallbackPage
│
└─ /                     → Root redirect
```

### 7.2 Navigation Patterns

#### 7.2.1 Declarative Navigation
```dart
// Define routes
GoRoute(
  name: 'service-details',
  path: '/services/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ServiceDetailsPage(serviceId: id);
  },
)

// Navigate using path
context.go('/services/facebook');

// Navigate using name
context.goNamed('service-details', pathParameters: {'id': 'facebook'});
```

#### 7.2.2 Passing Complex Data
```dart
// Define route with extra parameter
GoRoute(
  name: 'area-edit',
  path: '/areas/edit',
  builder: (context, state) {
    final area = state.extra as Area; // Get passed object
    return AreaFormPage(areaToEdit: area);
  },
)

// Navigate with object
context.goNamed('area-edit', extra: selectedArea);
```

#### 7.2.3 Nested Navigation
```dart
GoRoute(
  path: '/services',
  builder: (context, state) => ServicesListPage(),
  routes: [
    // Child route: /services/:id
    GoRoute(
      path: ':serviceId',
      builder: (context, state) {
        final id = state.pathParameters['serviceId']!;
        return ServiceDetailsPage(serviceId: id);
      },
    ),
  ],
)
```

### 7.3 Authentication Guards

```dart
// ShellRoute with AuthWrapperPage
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
    // All routes here require authentication
  ],
)

// AuthWrapperPage checks auth state
class AuthWrapperPage extends StatefulWidget {
  final Widget authenticatedChild;
  
  const AuthWrapperPage({required this.authenticatedChild});
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return authenticatedChild;
        }
        return LoginPage(); // Redirect to login
      },
    );
  }
}
```

### 7.4 Bottom Navigation Integration

```dart
class MainScaffold extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedIndex = AppNavigationItems.getIndexFromPath(currentLocation);
    
    return Scaffold(
      body: child, // Current page
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final destination = AppNavigationItems.destinations[index];
          context.go(destination.path);
        },
      ),
    );
  }
}
```

---

## 8. Dependency Management

### 8.1 Dependency Injection Architecture

```
┌───────────────────────────────────────┐
│     GetIt Service Locator (sl)        │
│                                        │
│  ┌──────────────────────────────┐    │
│  │  Core Dependencies            │    │
│  │  - ApiClient (Singleton)      │    │
│  │  - Storage Managers           │    │
│  └──────────────────────────────┘    │
│              │                         │
│              ↓                         │
│  ┌──────────────────────────────┐    │
│  │  Feature Dependencies         │    │
│  │  - DataSources                │    │
│  │  - Repositories               │    │
│  └──────────────────────────────┘    │
│              │                         │
│              ↓                         │
│  ┌──────────────────────────────┐    │
│  │  Presentation Dependencies    │    │
│  │  - BLoCs (Factory)            │    │
│  │  - Cubits (Factory)           │    │
│  └──────────────────────────────┘    │
└───────────────────────────────────────┘
```

### 8.2 Registration Strategy

**Singleton** (One instance for app lifetime)
```dart
sl.registerSingleton<ApiClient>(
  ApiClient(cookieDirPath: '${supportDir.path}/cookies'),
);

// Always returns same instance
final client1 = sl<ApiClient>();
final client2 = sl<ApiClient>();
// client1 == client2 ✅
```

**Lazy Singleton** (Created on first access, then reused)
```dart
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(sl(), sl()),
);

// Not created until first call to sl<AuthRepository>()
```

**Factory** (New instance every time)
```dart
sl.registerFactory<LoginCubit>(
  () => LoginCubit(sl()),
);

// Always returns new instance
final cubit1 = sl<LoginCubit>();
final cubit2 = sl<LoginCubit>();
// cubit1 != cubit2 ✅
```

### 8.3 Dependency Graph

```
main()
  │
  └─→ initCoreDependencies()
      │
      ├─→ Register Core
      │   ├─ ApiClient (Lazy Singleton)
      │   ├─ SecureStorageManager (Lazy Singleton)
      │   ├─ LocalPrefsManager (Lazy Singleton)
      │   └─ CacheManager (Lazy Singleton)
      │
      ├─→ Register Auth Feature
      │   ├─ AuthRemoteDataSource (Lazy Singleton)
      │   │   └─ depends on: ApiClient
      │   │
      │   ├─ AuthLocalDataSource (Lazy Singleton)
      │   │   └─ depends on: LocalPrefsManager
      │   │
      │   ├─ AuthRepository (Lazy Singleton)
      │   │   └─ depends on: AuthRemoteDataSource, AuthLocalDataSource
      │   │
      │   └─ AuthBloc (Factory)
      │       └─ depends on: AuthRepository
      │
      ├─→ Register Services Feature
      │   ├─ ServicesRemoteDataSource (Lazy Singleton)
      │   │   └─ depends on: ApiClient
      │   │
      │   └─ ServicesRepository (Lazy Singleton)
      │       └─ depends on: ServicesRemoteDataSource
      │
      └─→ Register Areas Feature
          └─ AreaRepository (Lazy Singleton)
```

### 8.4 Resolving Dependencies

**Automatic Resolution**
```dart
// GetIt automatically resolves dependencies
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(
    sl<AuthRemoteDataSource>(),  // Auto-resolved
    sl<AuthLocalDataSource>(),   // Auto-resolved
  ),
);
```

**Manual Resolution in Widgets**
```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(), // Resolves from service locator
      child: LoginPageContent(),
    );
  }
}
```

---

## 9. Feature Modules Architecture

### 9.1 Auth Feature

#### Purpose
Manage user authentication and session

#### Components
- **Entities**: User, AuthSession
- **Use Cases**: LoginUser, RegisterUser, LogoutUser, VerifyEmail
- **Repositories**: AuthRepository
- **BLoCs**: AuthBloc (global), LoginCubit, RegisterCubit, OAuthCubit

#### Architecture
```
auth/
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── auth_session.dart
│   │   └── oauth_provider.dart
│   │
│   ├── repositories/
│   │   └── auth_repository.dart
│   │
│   ├── use_cases/
│   │   ├── login_user.dart
│   │   ├── register_user.dart
│   │   ├── verify_email.dart
│   │   └── get_current_user.dart
│   │
│   ├── value_objects/
│   │   ├── email.dart
│   │   └── password.dart
│   │
│   └── exceptions/
│       ├── auth_exceptions.dart
│       └── oauth_exceptions.dart
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── auth_response_model.dart
│   │   └── register_response_model.dart
│   │
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart
│   │   └── auth_local_datasource.dart
│   │
│   └── repositories/
│       └── auth_repository_impl.dart
│
└── presentation/
    ├── blocs/
    │   ├── auth_bloc.dart          (Global auth state)
    │   ├── login/
    │   │   ├── login_cubit.dart
    │   │   └── login_state.dart
    │   ├── register/
    │   │   ├── register_cubit.dart
    │   │   └── register_state.dart
    │   └── oauth/
    │       ├── oauth_cubit.dart
    │       └── oauth_state.dart
    │
    ├── pages/
    │   ├── login_page.dart
    │   ├── register_page.dart
    │   ├── email_verification_page.dart
    │   └── oauth_callback_page.dart
    │
    ├── widgets/
    │   ├── forms/
    │   ├── buttons/
    │   └── common/
    │
    └── router/
        └── auth_router.dart
```

### 9.2 Services Feature

#### Purpose
Manage third-party service integration and subscriptions

#### Key Entities
- **ServiceProvider**: Represents a third-party service (Google, Facebook, etc.)
- **ServiceComponent**: Action or Reaction component provided by a service
- **UserServiceSubscription**: User's subscription to a service

#### Architecture Highlights
```
services/
├── domain/
│   ├── entities/
│   │   ├── service_provider.dart
│   │   ├── service_component.dart
│   │   ├── service_with_status.dart
│   │   └── user_service_subscription.dart
│   │
│   ├── value_objects/
│   │   ├── service_category.dart
│   │   ├── component_kind.dart          (Action/Reaction)
│   │   ├── auth_kind.dart               (OAuth2, API Key, None)
│   │   └── subscription_status.dart
│   │
│   └── use_cases/
│       ├── get_services_with_status.dart
│       ├── get_service_details.dart
│       ├── get_service_components.dart
│       ├── subscribe_to_service.dart
│       └── unsubscribe_from_service.dart
│
├── data/
│   ├── datasources/
│   │   └── services_remote_datasource.dart
│   │
│   ├── models/
│   │   ├── about_info_model.dart        (Server metadata)
│   │   ├── service_provider_model.dart
│   │   └── service_component_model.dart
│   │
│   └── repositories/
│       └── services_repository_impl.dart
│
└── presentation/
    ├── blocs/
    │   ├── services_list/
    │   │   ├── services_list_bloc.dart
    │   │   ├── services_list_event.dart
    │   │   └── services_list_state.dart
    │   │
    │   ├── service_details/
    │   │   ├── service_details_bloc.dart
    │   │   ├── service_details_event.dart
    │   │   └── service_details_state.dart
    │   │
    │   └── service_subscription/
    │       ├── service_subscription_cubit.dart
    │       └── service_subscription_state.dart
    │
    └── pages/
        ├── services_list_page.dart
        └── service_details_page.dart
```

### 9.3 Areas Feature

#### Purpose
Create and manage automation workflows (Action → Reaction)

#### Key Entities
- **Area**: Automation rule connecting an Action to a Reaction

#### Architecture Highlights
```
areas/
├── domain/
│   ├── entities/
│   │   └── area.dart
│   │
│   ├── repositories/
│   │   └── area_repository.dart
│   │
│   └── use_cases/
│       ├── get_areas.dart
│       ├── create_area.dart
│       ├── update_area.dart
│       └── delete_area.dart
│
├── data/
│   └── repositories/
│       └── area_repository_impl.dart   (Mock implementation)
│
└── presentation/
    ├── cubits/
    │   ├── areas_cubit.dart
    │   ├── areas_state.dart
    │   ├── area_form_cubit.dart
    │   └── area_form_state.dart
    │
    ├── pages/
    │   ├── areas_page.dart
    │   └── area_form_page.dart
    │
    └── widgets/
        ├── area_card.dart
        ├── service_picker_sheet.dart
        └── service_and_component_picker.dart
```

#### Cross-Feature Integration
```dart
class AreaFormCubit extends Cubit<AreaFormState> {
  late final GetSubscriptionForService _getSubscription;
  late final GetServiceComponents _getComponents;
  
  AreaFormCubit(
    AreaRepository areaRepository,
    ServicesRepository servicesRepository, // ← Cross-feature dependency
  ) : super(AreaFormInitial()) {
    _getSubscription = GetSubscriptionForService(servicesRepository);
    _getComponents = GetServiceComponents(servicesRepository);
  }
  
  // Can check if user is subscribed to a service
  Future<bool> checkSubscriptionActive(String providerId) async {
    // Uses Services feature functionality
  }
  
  // Can get components from a service
  Future<List<ServiceComponent>> getComponentsFor(
    String providerId,
    {required ComponentKind kind}
  ) async {
    // Uses Services feature functionality
  }
}
```

---

## 10. Cross-Cutting Concerns

### 10.1 Error Handling Strategy

#### Error Hierarchy
```
Exception (Dart)
    │
    ├─ NetworkException
    │   ├─ ConnectionTimeoutException
    │   ├─ ConnectionErrorException
    │   └─ BadResponseException
    │
    ├─ AuthException
    │   ├─ InvalidCredentialsException
    │   ├─ UserNotAuthenticatedException
    │   └─ TokenExpiredException
    │
    └─ StorageException
        ├─ ReadException
        └─ WriteException

Failure (Domain)
    │
    ├─ NetworkFailure
    ├─ UnauthorizedFailure
    ├─ StorageFailure
    └─ UnknownFailure
```

#### Error Flow
```
Data Layer (Throws Exception)
    │
    ↓
Repository catches Exception
    │
    ↓
Converts to Failure
    │
    ↓
Returns Either<Failure, T>
    │
    ↓
Use Case forwards Either
    │
    ↓
BLoC handles Failure
    │
    ↓
Emits Error State with user-friendly message
    │
    ↓
UI displays error to user
```

### 10.2 Logging Architecture

#### Logging Levels
```dart
class LogLevel {
  static const DEBUG = 0;
  static const INFO = 1;
  static const WARNING = 2;
  static const ERROR = 3;
}

class AppLogger {
  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      print('[DEBUG] $message ${data ?? ''}');
    }
  }
  
  static void error(String message, [dynamic error, StackTrace? stack]) {
    print('[ERROR] $message');
    if (error != null) print(error);
    if (stack != null) print(stack);
  }
}
```

#### Logging Points
- API requests/responses (via LoggingInterceptor)
- BLoC state changes (via BlocObserver)
- Navigation changes (via NavigatorObserver)
- Errors (via error handlers)

### 10.3 Caching Strategy

#### Cache Layers
```
Memory Cache (CacheManager)
    ↓ fallback
Local Storage (SharedPreferences / SQLite)
    ↓ fallback
Remote API
```

#### Cache Invalidation
```dart
class CacheStrategy {
  // Time-based expiration
  static const Duration cacheExpiration = Duration(hours: 1);
  
  // Check if cache is valid
  bool isCacheValid(DateTime lastUpdated) {
    return DateTime.now().difference(lastUpdated) < cacheExpiration;
  }
  
  // Manual invalidation
  Future<void> invalidateCache(String key) async {
    await _cacheManager.delete(key);
    await _localStorage.delete(key);
  }
}
```

### 10.4 Security Considerations

#### Sensitive Data Storage
```dart
// ✅ Use SecureStorage for sensitive data
await secureStorage.write(StorageKeys.authToken, token);

// ❌ Don't use SharedPreferences for sensitive data
await prefs.setString('auth_token', token); // ❌ Insecure
```

#### API Security
```dart
// ✅ Cookies managed automatically (HttpOnly, Secure)
final cookieJar = PersistCookieJar(
  ignoreExpires: false,
  storage: FileStorage(cookiesPath),
);

// ✅ HTTPS enforced in production
static const String baseUrl = "https://api.area.com";
```

#### Input Validation
```dart
// ✅ Validate at domain boundaries
class Email {
  factory Email(String input) {
    if (!_isValidEmail(input)) {
      throw InvalidEmailException(input);
    }
    return Email._(input);
  }
}

// ✅ Sanitize user input
String sanitizeInput(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML
      .replaceAll(RegExp(r'[^\w\s@.]'), ''); // Remove special chars
}
```

### 10.5 Performance Optimization

#### Widget Optimization
```dart
// ✅ Use const constructors
const Padding(
  padding: EdgeInsets.all(16.0),
  child: Text('Hello'),
)

// ✅ Extract expensive widgets
Widget _buildComplexWidget() {
  // Only rebuilds when parent changes
}

// ✅ Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

#### State Optimization
```dart
// ✅ Use BlocSelector for partial rebuilds
BlocSelector<MyBloc, MyState, int>(
  selector: (state) => state.counter, // Only rebuild when counter changes
  builder: (context, counter) => Text('$counter'),
)

// ✅ Use Equatable to prevent unnecessary rebuilds
@override
List<Object?> get props => [items]; // Only rebuild if items change
```

#### Network Optimization
```dart
// ✅ Implement retry logic
class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && _retryCount < maxRetries) {
      final delay = pow(2, _retryCount).toInt();
      await Future.delayed(Duration(seconds: delay));
      // Retry request
    }
  }
}

// ✅ Cache responses
@override
Future<List<Service>> getServices() async {
  // Check cache first
  final cached = _cache.read<List<Service>>('services');
  if (cached != null) return cached;
  
  // Fetch from network
  final services = await _remoteDataSource.getServices();
  _cache.write('services', services);
  
  return services;
}
```

---

## 11. Design Patterns & Best Practices

### 11.1 Design Patterns Used

#### Repository Pattern
**Purpose**: Abstract data source details from business logic

```dart
// Interface (Domain)
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
}

// Implementation (Data)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  
  @override
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      // Try remote first
      final userModel = await _remoteDataSource.getUser(id);
      await _localDataSource.cacheUser(userModel);
      return Right(userModel.toDomain());
    } catch (e) {
      // Fallback to cache
      final cached = await _localDataSource.getCachedUser(id);
      if (cached != null) return Right(cached.toDomain());
      return Left(NetworkFailure('User not found'));
    }
  }
}
```

#### Use Case Pattern
**Purpose**: Encapsulate single business operations

```dart
class SubscribeToService {
  final ServicesRepository _repository;
  
  SubscribeToService(this._repository);
  
  Future<Either<Failure, UserServiceSubscription>> call({
    required String serviceId,
    required List<String> requestedScopes,
  }) async {
    return await _repository.subscribeToService(
      serviceId: serviceId,
      requestedScopes: requestedScopes,
    );
  }
}

// Usage
final result = await _subscribeToService(
  serviceId: 'google',
  requestedScopes: ['email', 'profile'],
);
```

#### Factory Pattern
**Purpose**: Create objects without specifying exact class

```dart
class ServiceProviderModel {
  factory ServiceProviderModel.fromServiceName(String serviceName) {
    final category = _inferCategory(serviceName);
    
    return ServiceProviderModel(
      id: serviceName.toLowerCase().replaceAll(' ', '_'),
      name: serviceName.toLowerCase(),
      displayName: _formatDisplayName(serviceName),
      category: category,
      oauthType: AuthKind.oauth2,
      authConfig: {},
      isEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static ServiceCategory _inferCategory(String serviceName) {
    if (serviceName.contains('drive')) return ServiceCategory.storage;
    if (serviceName.contains('gmail')) return ServiceCategory.communication;
    return ServiceCategory.other;
  }
}
```

#### Observer Pattern
**Purpose**: Notify subscribers of state changes

```dart
// BLoC implements Observer pattern
class LoginCubit extends Cubit<LoginState> {
  // UI subscribes to state stream
  @override
  Stream<LoginState> get stream => super.stream;
  
  // Notify observers
  void login(String email, String password) {
    emit(LoginLoading()); // Notifies all listeners
    // ...
  }
}

// UI observes changes
BlocBuilder<LoginCubit, LoginState>(
  builder: (context, state) {
    // Automatically called when state changes
    return Text(state.toString());
  },
)
```

#### Dependency Injection Pattern
**Purpose**: Inject dependencies rather than create them

```dart
// ✅ Dependency Injection
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository; // Injected
  
  LoginCubit(this._repository) : super(LoginInitial());
}

// ❌ Hard-coded dependency
class LoginCubit extends Cubit<LoginState> {
  final _repository = AuthRepositoryImpl(); // ❌ Tight coupling
  
  LoginCubit() : super(LoginInitial());
}
```

### 11.2 SOLID in Practice

#### Single Responsibility
```dart
// ✅ Each class has one responsibility

// Handles only API communication
class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
}

// Handles only local storage
class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
}

// Coordinates data sources, handles errors
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  
  Future<Either<Failure, User>> login(...) {
    // Coordinates remote and local
  }
}
```

#### Open/Closed Principle
```dart
// Open for extension, closed for modification

// Can add new authentication methods without changing interface
abstract class AuthRepository {
  Future<Either<Failure, User>> login(Email email, Password password);
  Future<Either<Failure, User>> loginWithBiometric(); // New method
  Future<Either<Failure, User>> loginWithOAuth(OAuthProvider provider); // New method
}

// Existing code doesn't break when new methods added
```

#### Liskov Substitution
```dart
// Any implementation can replace the interface

AuthRepository repo = AuthRepositoryImpl(...);  // Production
AuthRepository testRepo = MockAuthRepository(); // Testing

// Both work identically from consumer perspective
final result = await repo.login(email, password);
```

#### Interface Segregation
```dart
// ✅ Small, focused interfaces

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<RegisterResponseModel> register(String email, String password);
  Future<void> logout();
}

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

// ❌ One large interface (violates ISP)
abstract class AuthDataSource {
  // Remote methods
  Future<AuthResponseModel> login(...);
  Future<RegisterResponseModel> register(...);
  // Local methods
  Future<void> cacheUser(...);
  Future<UserModel?> getCachedUser();
  // Not all implementations need all methods
}
```

#### Dependency Inversion
```dart
// High-level modules depend on abstractions

// ✅ Depends on abstraction
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository; // Abstract interface
  
  LoginCubit(this._repository) : super(LoginInitial());
}

// ❌ Depends on concrete implementation
class LoginCubit extends Cubit<LoginState> {
  final AuthRepositoryImpl _repository; // Concrete class
  
  LoginCubit(this._repository) : super(LoginInitial());
}
```

### 11.3 Code Quality Guidelines

#### Naming Conventions
```dart
// Classes: PascalCase
class UserRepository {}
class LoginCubit {}

// Files: snake_case
user_repository.dart
login_cubit.dart

// Variables: camelCase
final authRepository = ...;
final currentUser = ...;

// Constants: lowerCamelCase or SCREAMING_SNAKE_CASE
const apiTimeout = Duration(seconds: 30);
const API_TIMEOUT = Duration(seconds: 30);

// Private members: _prefixed
final _repository = ...;
void _handleError() {}
```

#### Documentation
```dart
/// Authenticates a user with email and password.
///
/// Returns [Either] with [User] on success or [Failure] on error.
///
/// Throws [InvalidEmailException] if email format is invalid.
/// Throws [WeakPasswordException] if password is too weak.
///
/// Example:
/// ```dart
/// final result = await authRepository.login(
///   Email('user@example.com'),
///   Password('securePassword123'),
/// );
/// ```
Future<Either<Failure, User>> login(Email email, Password password);
```

#### Error Handling
```dart
// ✅ Specific error handling
try {
  final result = await repository.getData();
  result.fold(
    (failure) => _handleSpecificFailure(failure),
    (data) => _handleSuccess(data),
  );
} on NetworkException catch (e) {
  _showNetworkError(e.message);
} on UnauthorizedException {
  _redirectToLogin();
} catch (e) {
  _showGenericError();
}

// ❌ Generic catch-all
try {
  final result = await repository.getData();
  // Use result
} catch (e) {
  print(e); // ❌ Don't just print
}
```

---

## 12. Architecture Decision Records

### ADR-001: Clean Architecture Adoption

**Status**: Accepted  
**Date**: 2024-10  
**Deciders**: Development Team

**Context**:
Need architecture that supports testability, maintainability, and scalability for a complex automation platform.

**Decision**:
Adopt Clean Architecture with three layers: Presentation, Domain, Data.

**Consequences**:
✅ **Positive**:
- Clear separation of concerns
- Highly testable (each layer independently)
- Business logic independent of frameworks
- Easy to replace data sources

❌ **Negative**:
- More initial boilerplate
- Learning curve for new developers
- More files/folders

---

### ADR-002: BLoC for State Management

**Status**: Accepted  
**Date**: 2024-10  
**Deciders**: Development Team

**Context**:
Need predictable, testable state management that separates business logic from UI.

**Decision**:
Use BLoC/Cubit pattern from flutter_bloc package.

**Consequences**:
✅ **Positive**:
- Predictable state transitions
- Easy to test business logic
- Time-travel debugging possible
- Well-documented and maintained

❌ **Negative**:
- Boilerplate for simple features
- Stream-based (learning curve)

---

### ADR-003: Either Monad for Error Handling

**Status**: Accepted  
**Date**: 2024-10  
**Deciders**: Development Team

**Context**:
Need functional error handling that makes errors explicit in type system.

**Decision**:
Use `Either<Failure, Success>` from dartz package.

**Consequences**:
✅ **Positive**:
- Errors explicit in function signatures
- Forces error handling
- Composable (functional style)
- No uncaught exceptions in business logic

❌ **Negative**:
- Functional programming paradigm (learning curve)
- More verbose than try-catch
- Additional dependency (dartz)

---

### ADR-004: Feature-Based Module Structure

**Status**: Accepted  
**Date**: 2024-10  
**Deciders**: Development Team

**Context**:
Need to organize code in a way that scales with app complexity.

**Decision**:
Organize code by feature (auth, services, areas) with Clean Architecture layers inside each feature.

**Consequences**:
✅ **Positive**:
- Clear feature boundaries
- Easy to find code related to a feature
- Can work on features independently
- Can extract features to packages if needed

❌ **Negative**:
- Some code duplication across features
- Need conventions for cross-feature communication

---

### ADR-005: Go Router for Navigation

**Status**: Accepted  
**Date**: 2024-10  
**Deciders**: Development Team

**Context**:
Need declarative routing with deep linking support.

**Decision**:
Use go_router package for navigation.

**Consequences**:
✅ **Positive**:
- Declarative routing
- Deep linking support
- Type-safe navigation
- Route guards (authentication)
- Nested navigation

❌ **Negative**:
- Different from imperative Navigator 1.0
- Complex for advanced use cases
- Breaking changes between versions

---


**Revision History**:
- v1.0 (2025-04/10): Initial architecture documentation
