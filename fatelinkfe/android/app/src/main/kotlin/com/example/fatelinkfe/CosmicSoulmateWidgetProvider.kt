package com.example.fatelinkfe

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class CosmicSoulmateWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.cosmic_soulmate_widget).apply {
                val headline = widgetData.getString("headline", "✦ FATELINK 432Hz") ?: "✦ FATELINK 432Hz"
                val name = widgetData.getString("soulmate_name", "Tri kỷ FateLink") ?: "Tri kỷ FateLink"
                val vibe = widgetData.getString("soulmate_vibe", "Đang hòa âm tần số cảm xúc") ?: "Đang hòa âm tần số cảm xúc"
                val harmony = widgetData.getString("soulmate_harmony", "95% Hòa âm") ?: "95% Hòa âm"
                val distance = widgetData.getString("soulmate_distance", "📍 Đang ở gần bạn") ?: "📍 Đang ở gần bạn"

                setTextViewText(R.id.widget_headline, headline)
                setTextViewText(R.id.widget_soulmate_name, name)
                setTextViewText(R.id.widget_soulmate_vibe, vibe)
                setTextViewText(R.id.widget_soulmate_harmony, harmony)
                setTextViewText(R.id.widget_soulmate_distance, distance)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fatelink://match")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
