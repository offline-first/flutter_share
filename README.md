Share files
# PLUGIN UNDER CONSTRUCTION (iOS not completed)

# Using
- Share file 
```
await FlutterShare.file(file.path);
```
- Share with Whatsapp 
```
await FlutterShare.shareWhatsapp(filePath: file.path, text: "optional text");
```

- Check installed....
```
print("Telegram Installed:${await FlutterShare.telegramInstalled()}");
print("Facebook Installed:${await FlutterShare.facebookInstalled()}");
print("Instagram Installed:${await FlutterShare.instagramInstalled()}");
print("Twitter Installed:${await FlutterShare.twitterInstalled()}");
```


# Setup

## Android Configuration
1. add this to `AndroidManifest.xml `
    $`xmlns:tools="http://schemas.android.com/tools"`
    eg: 
    $```<manifest xmlns:android="http://schemas.android.com/apk/res/android"
                  xmlns:tools="http://schemas.android.com/tools"
                  package="your package...">```
                          
2. add this to `AndroidManifest.xml` inside application tag
    ```<provider
           android:name="androidx.core.content.FileProvider"
           android:authorities="${applicationId}.flutter_share"
           android:exported="false"
           android:grantUriPermissions="true"
           tools:replace="android:authorities">
           <meta-data
               android:name="android.support.FILE_PROVIDER_PATHS"
               android:resource="@xml/filepaths" />
       </provider>```
   
 3. Create a xml file named `file_paths.xml` in the `app/src/main/res/xml` folder and paste this code in the file: 
    ```<?xml version="1.0" encoding="utf-8"?>
       <paths xmlns:android="http://schemas.android.com/apk/res/android">
           <cache-path name="files" path="/"/>
       </paths>``` 
    
## iOS Configuration    

1. Add this to your `Info.plist` to use share on instagram and facebook story
```<key>LSApplicationQueriesSchemes</key>
   	<array>
        <string>instagram-stories</string>
        <string>facebook-stories</string>
        <string>facebook</string>
        <string>instagram</string>
        <string>twitter</string>
        <string>whatsapp</string>
        <string>tg</string>
   	</array>```

