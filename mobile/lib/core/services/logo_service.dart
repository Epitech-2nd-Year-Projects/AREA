import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogoService {
  static const String _baseUrl = 'https://img.logo.dev';
  
  static String getLogoUrl(String serviceName) {
    final token = dotenv.env['LOGO_DEV_TOKEN'] ?? '';
    final domain = _normalizeDomain(serviceName);
    return '$_baseUrl/$domain?token=$token';
  }

  static String _normalizeDomain(String serviceName) {
    final normalized = serviceName.toLowerCase();
    
    final domainMap = {
      'github': 'github.com',
      'google': 'google.com',
      'microsoft': 'microsoft.com',
      'twitter': 'twitter.com',
      'x': 'x.com',
      'discord': 'discord.com',
      'slack': 'slack.com',
      'stripe': 'stripe.com',
      'paypal': 'paypal.com',
      'twitch': 'twitch.tv',
      'youtube': 'youtube.com',
      'instagram': 'instagram.com',
      'facebook': 'facebook.com',
      'linkedin': 'linkedin.com',
      'linear': 'linear.app',
      'reddit': 'reddit.com',
      'spotify': 'spotify.com',
      'zoom': 'zoom.com',
      'teams': 'microsoft.com/teams',
      'notion': 'notion.so',
      'asana': 'asana.com',
      'jira': 'jira.atlassian.com',
      'confluence': 'confluence.atlassian.com',
      'trello': 'trello.com',
      'figma': 'figma.com',
      'dribbble': 'dribbble.com',
      'behance': 'behance.net',
      'dropbox': 'dropbox.com',
      'box': 'box.com',
      'onedrive': 'onedrive.live.com',
      'aws': 'aws.amazon.com',
      'azure': 'azure.microsoft.com',
      'gcp': 'cloud.google.com',
      'heroku': 'heroku.com',
      'digitalocean': 'digitalocean.com',
      'vercel': 'vercel.com',
      'netlify': 'netlify.com',
      'github pages': 'pages.github.com',
    };
    
    return domainMap[normalized] ?? '$normalized.com';
  }
}