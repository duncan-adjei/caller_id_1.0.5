package com.firstorion.engageplugin.flutter_engage_plugin_example

import android.util.Log
import com.firstorion.engage.core.EngageApp
import com.firstorion.engage.core.IEngageLoggingInterceptor
import io.flutter.app.FlutterApplication

class MyApplication : FlutterApplication(), IEngageLoggingInterceptor {

    override fun onCreate() {
        super.onCreate()
        // Initialized Engage in the application class because, on device reboot,
        // we need to ensure the app is initialized first for the Koin module in Engage Android.

        // if host app not use firebase in flutter app than call this method
        //EngageApp.initializeEngage(this)

        // if host app use the firebase in flutter app than call this method
        EngageApp.initializeEngageForFlutterFirebase(this)

        EngageApp.Settings.setLoggingInterceptor(this)
        EngageApp.Settings.setMinimumLoggingLevel(Log.VERBOSE)

    }
    override fun intercept(message: String, level: Int) {
        println("engage.app  $message" )
    }
}