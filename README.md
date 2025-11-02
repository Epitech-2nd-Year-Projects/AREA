# AREA - Action REAction Automation Platform

<div align="center">

![AREA Logo](mobile/assets/Area_logo_android.png)

**A powerful automation platform that connects your favorite services and creates seamless workflows**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![Go](https://img.shields.io/badge/Go-1.25.3-00ADD8?logo=go)](https://golang.org)
[![Next.js](https://img.shields.io/badge/Next.js-15.5.3-000000?logo=next.js)](https://nextjs.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)

</div>

## 🚀 Overview

AREA is a comprehensive automation platform inspired by IFTTT and Zapier, designed to connect various services and create powerful automated workflows. When an **Action** (trigger) occurs on one service, a **REAction** (response) is automatically executed on another service.

The platform consists of three main components:
- **🖥️ Web Application**: Modern Next.js frontend with server-side rendering
- **📱 Mobile Application**: Cross-platform Flutter app for Android
- **⚙️ Backend Server**: Robust Go API server with comprehensive automation engine

## ✨ Key Features

### 🔗 Service Integrations
- **GitHub**: Repository events, issue management, pull requests
- **Google Services**: Gmail, Google Drive, Google Calendar
- **Microsoft**: Office 365, Outlook integration
- **Communication**: Slack, Zoom, Discord
- **Development**: GitLab, Linear, Notion
- **Entertainment**: Spotify, Reddit
- **Storage**: Dropbox, OneDrive
- **Utilities**: Timer/Scheduler, Custom webhooks

### 🎯 Core Capabilities
- **OAuth2 Authentication**: Secure service connections
- **Real-time Automation**: Instant trigger detection and response execution
- **Visual Workflow Builder**: Intuitive drag-and-drop interface
- **Multi-platform Access**: Web, mobile, and API access
- **Comprehensive Monitoring**: Detailed logs and execution tracking
- **Internationalization**: Multi-language support
- **Accessibility**: WCAG compliant interfaces

## 🏗️ Architecture

### System Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Client    │    │  Mobile Client  │    │   API Server    │
│   (Next.js)     │◄──►│   (Flutter)     │◄──►│     (Go)        │
│   Port: 8081    │    │   Android APK   │    │   Port: 8080    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                               ┌───────▼───────┐
                                               │   Database    │
                                               │ (PostgreSQL)  │
                                               └───────────────┘
```

### Technology Stack

#### Backend (Go)
- **Framework**: Gin HTTP framework
- **Database**: PostgreSQL with GORM ORM
- **Authentication**: JWT tokens with secure sessions
- **Caching**: Redis for session management
- **Email**: SendGrid integration
- **Architecture**: Clean Architecture with hexagonal design

#### Web Frontend (Next.js)
- **Framework**: Next.js 15.5.3 with App Router
- **UI Library**: Radix UI components with Tailwind CSS
- **State Management**: React Query (TanStack Query)
- **Internationalization**: next-intl
- **Testing**: Vitest with comprehensive E2E coverage

#### Mobile Application (Flutter)
- **Architecture**: Clean Architecture with BLoC pattern
- **State Management**: Flutter BLoC/Cubit
- **HTTP Client**: Dio with cookie management
- **Storage**: Secure storage and shared preferences
- **Navigation**: Go Router for declarative routing
- **Testing**: 65+ comprehensive test scenarios

## 🚀 Quick Start

### Prerequisites
- **Docker & Docker Compose** (recommended)
- **Go** ≥ 1.25.1
- **Node.js** ≥ 20 with npm
- **Flutter** stable channel (for mobile development)

### Using Docker Compose (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/Epitech-2nd-Year-Projects/AREA.git
   cd AREA
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Build and run**
   ```bash
   docker compose build
   docker compose up
   ```

4. **Verify deployment**
   ```bash
   # Check API server
   curl http://localhost:8080/about.json
   
   # Check web client
   curl -I http://localhost:8081
   
   # Download mobile APK
   curl -O http://localhost:8081/client.apk
   ```

### Local Development

#### Backend Server
```bash
cd server
go mod download
go run ./cmd/server
```

#### Web Application
```bash
cd web
npm install
npm run dev
```

#### Mobile Application
```bash
cd mobile
flutter pub get
flutter run
```

## 📱 Mobile Application

The AREA mobile application provides full platform functionality on Android devices with:

- **Clean Architecture**: Maintainable, testable, and scalable codebase
- **Professional UI/UX**: Material Design with custom animations
- **Offline Support**: Local caching and synchronization
- **Comprehensive Testing**: 65+ test scenarios covering all user flows
- **Accessibility**: Full screen reader and navigation support
- **Internationalization**: Multi-language support



## 🌐 Web Application

The web interface offers a comprehensive dashboard experience with:

- **Server-Side Rendering**: Optimized performance with Next.js App Router
- **Responsive Design**: Mobile-first approach with Tailwind CSS
- **Real-time Updates**: Live automation status and logs
- **Advanced UI Components**: Professional interface with Radix UI
- **Type Safety**: Full TypeScript integration with OpenAPI contracts

## 🔧 API Documentation

The AREA API provides comprehensive REST endpoints for all platform functionality:

- **Base URL**: `http://localhost:8080`
- **Authentication**: Cookie-based sessions with JWT tokens
- **Format**: JSON responses with OpenAPI 3.0 specification
- **CORS**: Configured for cross-origin requests

### Key Endpoints
- `GET /about.json` - Server metadata and available services
- `POST /v1/users` - User registration
- `POST /v1/auth/login` - User authentication
- `GET /v1/auth/me` - Current user profile
- `GET /v1/services` - Available service providers
- `POST /v1/areas` - Create automation workflows


## 🤝 Contributing

We welcome contributions! Please read our [HOWTOCONTRIBUTE.md](HOWTOCONTRIBUTE.md) for detailed guidelines on:

- Adding new service providers
- Implementing actions and reactions
- Extending the API
- Updating client applications
- Testing procedures

### Development Workflow
1. Fork the repository
2. Create a feature branch: `feature/<issue-id>-<feature-name>`
3. Follow conventional commits specification
4. Ensure all tests pass
5. Submit a pull request

### Code Quality
- **Husky**: Pre-commit hooks for formatting and linting
- **ESLint**: JavaScript/TypeScript code quality
- **Prettier**: Consistent code formatting
- **Go vet**: Go code analysis
- **Flutter analyze**: Dart code quality

## 📊 Project Statistics

- **Services Supported**: 11 major platforms
- **Actions Available**: 15 trigger types
- **Reactions Available**: 12 response types
- **Languages**: Go, TypeScript, Flutter (Dart)
- **Architecture**: Clean Architecture

## 👥 Team

This project was developed by a talented team of software engineers:

### 📱 Mobile Development
- **Enzo Gallini** - [enzo.gallini@epitech.eu](mailto:enzo.gallini@epitech.eu)
- **Laurent Aliu** - [laurent.aliu@epitech.eu](mailto:laurent.aliu@epitech.eu)

### ⚙️ Backend Development
- **Gregor Sternat** - [gregor.sternat@epitech.eu](mailto:gregor.sternat@epitech.eu)

### 🌐 Frontend Development
- **Yanis Kernoua** - [yanis.kernoua@epitech.eu](mailto:yanis.kernoua@epitech.eu)

## 📄 License

This project is part of the Epitech curriculum and is intended for educational purposes.

## 🔗 Links

- [Project Specification](G-DEV-500_AREA.pdf)
- [Contribution Guide](HOWTOCONTRIBUTE.md)
- [Mobile Architecture](mobile/docs/ARCHITECTURE_OVERVIEW.md)
- [Web Architecture](web/docs/ARCHITECTURE_OVERVIEW.md)

---

<div align="center">

**Built with ❤️ by the AREA Team**

*Connecting services, automating workflows, simplifying life*

</div>