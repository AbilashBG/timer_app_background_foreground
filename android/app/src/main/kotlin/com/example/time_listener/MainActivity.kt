
package com.example.time_listener
import android.annotation.TargetApi
import android.icu.text.SimpleDateFormat
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*


class MainActivity: FlutterActivity() {

    private val CHANNEL = "time_listener"

    @RequiresApi(Build.VERSION_CODES.N)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->

            if (call.method == "getSystemTime") {
                val data=getTime();
                result.success(data)
            }
            if (call.method == "getSystemDate") {
                val data=getDate();
                result.success(data)
            }
        }
    }

    @TargetApi(Build.VERSION_CODES.N)
    @RequiresApi(Build.VERSION_CODES.N)
    private fun getTime(): String? {
        val dateFormat = SimpleDateFormat("hh:mm:ss aa", Locale.getDefault())
        val currentTime = dateFormat.format(Date())
        return currentTime;
    }
    @TargetApi(Build.VERSION_CODES.N)
    private fun getDate(): String? {
        val dateFormat = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())
        val currentDate = dateFormat.format(Date())
        return currentDate;
    }
}
