package com.example.fatelinkfe

import android.content.Intent
import com.tiktok.open.sdk.auth.AuthApi
import com.tiktok.open.sdk.auth.AuthRequest
import com.tiktok.open.sdk.auth.utils.PKCEUtils
import com.zing.zalo.zalosdk.oauth.ZaloSDK
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val tiktokChannel = "fatelink/tiktok_auth"
    private var tikTokAuthApi: AuthApi? = null
    private var pendingTikTokLoginResult: MethodChannel.Result? = null
    private var tikTokCodeVerifier: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        tikTokAuthApi = AuthApi(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, tiktokChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "login" -> {
                        if (pendingTikTokLoginResult != null) {
                            result.error("ALREADY_RUNNING", "TikTok login is already in progress.", null)
                            return@setMethodCallHandler
                        }
                        pendingTikTokLoginResult = result
                        startTikTokLogin()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        ZaloSDK.Instance.onActivityResult(this, requestCode, resultCode, data)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleTikTokAuthResponse(intent)
    }

    override fun onResume() {
        super.onResume()
        handleTikTokAuthResponse(intent)
    }

    private fun startTikTokLogin() {
        val codeVerifier = PKCEUtils.generateCodeVerifier()
        tikTokCodeVerifier = codeVerifier
        val request = AuthRequest(
            clientKey = BuildConfig.TIKTOK_CLIENT_KEY,
            scope = "user.info.basic",
            redirectUri = BuildConfig.TIKTOK_REDIRECT_URL,
            codeVerifier = codeVerifier,
        )
        val launched = tikTokAuthApi?.authorize(request, AuthApi.AuthMethod.TikTokApp) == true
        if (!launched) {
            pendingTikTokLoginResult?.error(
                "TIKTOK_LOGIN_FAILED",
                "Unable to start TikTok authorization flow.",
                null,
            )
            pendingTikTokLoginResult = null
            tikTokCodeVerifier = null
        }
    }

    private fun handleTikTokAuthResponse(intent: Intent?) {
        val currentResult = pendingTikTokLoginResult ?: return
        val data = intent?.data

        if (data?.scheme == "fatelink" && data.host == "tiktok" && data.path == "/auth") {
            val code = data.getQueryParameter("code")
            if (!code.isNullOrEmpty()) {
                currentResult.success(
                    mapOf(
                        "code" to code,
                        "codeVerifier" to tikTokCodeVerifier,
                        "grantedPermissions" to (data.getQueryParameter("scopes") ?: ""),
                    )
                )
            } else {
                currentResult.error(
                    data.getQueryParameter("error") ?: "TIKTOK_AUTH_ERROR",
                    data.getQueryParameter("error_description") ?: "TikTok authorization failed.",
                    data.getQueryParameter("errCode"),
                )
            }
            pendingTikTokLoginResult = null
            tikTokCodeVerifier = null
            return
        }

        val response = tikTokAuthApi?.getAuthResponseFromIntent(intent, BuildConfig.TIKTOK_REDIRECT_URL)
            ?: return

        if (response.authCode.isNotEmpty()) {
            currentResult.success(
                mapOf(
                    "code" to response.authCode,
                    "codeVerifier" to tikTokCodeVerifier,
                    "grantedPermissions" to response.grantedPermissions,
                )
            )
        } else {
            currentResult.error(
                response.authError ?: "TIKTOK_AUTH_ERROR",
                response.authErrorDescription ?: response.errorMsg ?: "TikTok authorization failed.",
                response.errorCode,
            )
        }
        pendingTikTokLoginResult = null
        tikTokCodeVerifier = null
    }
}
