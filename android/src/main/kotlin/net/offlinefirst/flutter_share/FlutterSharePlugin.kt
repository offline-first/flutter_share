package net.offlinefirst.flutter_share

import android.app.PendingIntent
import android.content.*
import android.content.Intent.EXTRA_CHOSEN_COMPONENT
import android.net.Uri
import android.os.Build
import androidx.annotation.Keep
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File
import java.util.*

@Suppress("UNCHECKED_CAST")
@Keep
class FlutterSharePlugin(var registrar: Registrar): MethodCallHandler {

  companion object {
    const val PROVIDER_AUTH_EXT = "flutter_share"
    const val TWITTER_PACKAGE = "com.twitter.android"
    const val FACEBOOK_PACKAGE = "com.facebook.katana"
    const val INSTAGRAM_PACKAGE = "com.instagram.android"
    const val TELEGRAM_PACKAGE = "org.telegram.messenger"
    const val WHATS_APP_PACKAGE = "com.whatsapp"

    private const val SHARE_CHANNEL: String = "flutter_share"

    private lateinit var flutterResult:  Result

    @JvmStatic
    fun registerWith(reg: Registrar) {
      val channel = MethodChannel(reg.messenger(), SHARE_CHANNEL)
      channel.setMethodCallHandler(FlutterSharePlugin(reg))
    }

    fun onAppResume(packageName: String?) {
        val success = packageName != null
        this.flutterResult.success(success)
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
      flutterResult = result
      when(call.method){
          "text" -> text(call.arguments, result)
          "files" -> files(call.arguments, result)
          "file" -> file(call.arguments, result)
          "copyToClipboard" -> copyToClipboard(call.arguments, result)
          "isCallbackSupported" -> result.success(isCallbackSupported())
          "twitterInstalled" -> result.success(twitterInstalled())
          "facebookInstalled" -> result.success(facebookInstalled())
          "instagramInstalled" -> result.success(instagramInstalled())
      }
  }

  private fun twitterInstalled():Boolean = isPackageInstalled(TWITTER_PACKAGE)
  private fun facebookInstalled():Boolean = isPackageInstalled(FACEBOOK_PACKAGE)
  private fun instagramInstalled():Boolean = isPackageInstalled(INSTAGRAM_PACKAGE)
  private fun isCallbackSupported():Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1

  private fun isPackageInstalled(packageName: String) : Boolean {
      return try {
          registrar.activeContext().packageManager.getApplicationInfo(packageName, 0).enabled
      }catch (e: Exception){
          false
      }
  }

  @Keep
  private fun copyToClipboard(arguments: Any, result: Result){
    val argsMap =  arguments as HashMap<String, Any>
    val content: String = argsMap["text"] as String

    val clipboard = registrar.context().getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("", content)
    clipboard.setPrimaryClip(clip)
    result.success(true)
  }

  @Keep
  private fun text(arguments: Any, result: Result) {
    val argsMap = arguments as HashMap<String, String>;
    val title = argsMap["title"]
    val textToSend = argsMap["text"]
    val mimeType = argsMap["mimeType"]

    val shareIntent = Intent(Intent.ACTION_SEND)
    shareIntent.type = mimeType

    if(argsMap["shareType"] != null)
        shareIntent.applyProvider(argsMap["shareType"])

    shareIntent.putExtra(Intent.EXTRA_TEXT, textToSend)

    share(shareIntent, title, result)
  }

  private fun share(shareIntent: Intent, title: String?, result: Result){
      val activeContext = registrar.activeContext()
      val receiver = Intent(activeContext, OnShareReceiver::class.java)
      val pendingIntent = PendingIntent.getBroadcast(activeContext, 0, receiver, PendingIntent.FLAG_UPDATE_CURRENT)

      val chooserIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
          Intent.createChooser(shareIntent, title, pendingIntent.intentSender)
      }else{
          Intent.createChooser(shareIntent, title)
      }
      if(registrar.activity() == null){
          chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }

      try {
          activeContext.startActivity(chooserIntent)
          result.success(true)
      } catch (ex: ActivityNotFoundException) {
          result.success(false)
      }
  }

  private fun Intent.applyProvider(shareType: String?){
      if(shareType != null){
          when(shareType){
              "instagram" -> setPackage(INSTAGRAM_PACKAGE)
              "facebook" -> setPackage(FACEBOOK_PACKAGE)
              "twitter" -> setPackage(TWITTER_PACKAGE)
              "telegram" -> setPackage(TELEGRAM_PACKAGE)
              "whatsapp" -> setPackage(WHATS_APP_PACKAGE)
              else -> setPackage(shareType) //custom
          }
      }
  }

    @Keep
    private fun files(arguments: Any, result: Result) {
        val argsMap =  arguments as HashMap<String, Any>
        val title = argsMap["title"] as String
        val names = argsMap["names"] as ArrayList<String>
        val mimeType = argsMap["mimeType"] as String
        val text = argsMap["text"] as String

        val activeContext = registrar.activeContext()

        val shareIntent = Intent(Intent.ACTION_SEND_MULTIPLE)
        shareIntent.type = mimeType

        val contentUris = arrayListOf<Uri>()

        for (name in names) {
            val file = File(activeContext.cacheDir, name)
            contentUris.add(FileProvider.getUriForFile(activeContext, "${activeContext.packageName}.$PROVIDER_AUTH_EXT", file))
        }

        if (text.isNotEmpty()) {
            shareIntent.putExtra(Intent.EXTRA_TEXT, text)
        }

        shareIntent.applyProvider(argsMap["shareType"] as? String)
        shareIntent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, contentUris)
        share(shareIntent, title, result)
    }
    @Keep
    private fun file(arguments: Any, result: Result) {
        val argsMap = arguments as HashMap<String, String>
        val title = argsMap["title"]
        val path = argsMap["path"] as String
        val name = argsMap["name"] as String
        val text = argsMap["text"]
        val mimeType = argsMap["mimeType"]

        val activeContext = registrar.activeContext()

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            if (text?.isNotEmpty() == true) {
                putExtra(Intent.EXTRA_TEXT, text)
                setType("text/plain")
            }
            if(mimeType != null){
                setType(mimeType)
            }
            applyProvider(argsMap["shareType"])
        }

        val file = File(path)
        //val file = File(activeContext.cacheDir, name)
        if(file.exists()){
            val contentUri = FileProvider.getUriForFile(activeContext, "${activeContext.packageName}.$PROVIDER_AUTH_EXT", file)
            shareIntent.putExtra(Intent.EXTRA_STREAM, contentUri)
        }

        /*
        if(title?.isNotEmpty() == true){
          shareIntent.putExtra(Intent.EXTRA_SUBJECT, title)
        }
         */

        share(shareIntent, title, result)
    }
}

//class ShareResult(completed: Boolean, error: ShareError?)
//class ShareError(message: String, code:Int)

class OnShareReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val packageName = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            intent?.extras?.get(EXTRA_CHOSEN_COMPONENT).toString()
        } else {
            "unknown_old_android_version"
        }
        FlutterSharePlugin.onAppResume(packageName)
    }
}
