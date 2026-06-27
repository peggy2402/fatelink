package com.example.fatelinkfe

import android.app.Application
import com.zing.zalo.zalosdk.oauth.ZaloSDKApplication

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ZaloSDKApplication.wrap(this)
    }
}
