import 'dart:async';
import 'package:flutter/services.dart';

class FlutterShare {
  static const MethodChannel _channel = const MethodChannel('flutter_share');
 
  static Future text(String text, {String androidSubject, String provider, String mimeType = "text/plain"}) {
    Map argsMap = <String, String>{
      'title': '$androidSubject',
      'text': '$text',
      'mimeType': '$mimeType',
      if(provider != null)'shareType':provider
    };
    return _channel.invokeMethod('text', argsMap);
  }

  static Future<bool> shareTelegram({String filePath, String text, String mimeType}){
    return share(filePath: filePath, text: text, mimeType: mimeType, provider: ShareProvider.telegram);
  }

  static Future<bool> shareWhatsapp({String filePath, String text, String mimeType}){
    return share(filePath: filePath, text: text, mimeType: mimeType, provider: ShareProvider.whatsapp );
  }

  static Future<bool> shareFacebook({String filePath, String text, String mimeType}){
    return share(filePath: filePath, text: text, mimeType: mimeType, provider: ShareProvider.facebook);
  }

  static Future<bool> shareInstagram({String filePath, String text, String mimeType}){
    return share(filePath: filePath, text: text, mimeType: mimeType, provider: ShareProvider.instagram);
  }

  static Future<bool> shareTwitter({String filePath, String text, String mimeType}){
    return share(filePath: filePath, text: text, mimeType: mimeType, provider: ShareProvider.twitter);
  }
  
  static Future<bool> share({String filePath, String text, String mimeType, String provider}){
    if(filePath != null){
      return FlutterShare.file(filePath, text: text, mimeType: mimeType, provider: provider);
    }else{
      return FlutterShare.text(text, provider: provider);
    }
  }

  static Future<bool> file( String path, { String androidSubject = "", String text = "", String provider, String mimeType }) async {
    final fileName = path.split("/").last;
    final type = mimeType ?? "image/${path.split(".").last}";

    final map = <String, String>{
      'title': '$androidSubject',
      'name': '$fileName',
      'path': '$path',
      'text': '$text',
      'mimeType': '$type',
      if(provider != null)'shareType':provider
    };
 
    return _channel.invokeMethod('file', map);
  }

  static Future copyToClippboard(String text){
    print("copyToClippboard:$text");
    return _channel.invokeMethod('copyToClipboard', {'text': text});
  }

  static Future<bool> telegramInstalled(){
    return _channel.invokeMethod('telegramInstalled');
  }

  static Future<bool> twitterInstalled(){
    return _channel.invokeMethod('twitterInstalled');
  }

  static Future<bool> facebookInstalled(){
    return _channel.invokeMethod('facebookInstalled');
  }

  static Future<bool> instagramInstalled(){
    return _channel.invokeMethod('instagramInstalled');
  }

  static Future<bool> whatsappInstalled(){
    return _channel.invokeMethod('whatsappInstalled');
  }
/*
  static Future<void> files( Map<String, List<int>> files, String mimeType, {String shareType, String text = "", String androidSubject = ""}) async {

    Map argsMap = <String, dynamic>{
      'title': '$androidSubject',
      'text': '$text',
      'names': files.entries.toList().map((x) => x.key).toList(),
      'mimeType': mimeType
    };
    if(shareType != null){
      argsMap[ 'shareType'] = shareType;
    }
    final tempDir = await getTemporaryDirectory();

    for (final entry in files.entries) {
      final file = await File('${tempDir.path}/${entry.key}').create();
      await file.writeAsBytes(entry.value);
    }
    _channel.invokeMethod('files', argsMap);
  }

 */

}

class ShareProvider {
  static const String telegram = "telegram";
  static const String whatsapp = "whatsapp";
  static const String facebook = "facebook";
  static const String instagram = "instagram";
  static const String twitter = "twitter";
}
