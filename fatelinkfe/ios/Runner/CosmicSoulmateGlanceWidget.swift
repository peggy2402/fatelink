import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            name: "Tri kỷ FateLink",
            vibe: "Đang hòa âm tần số 432 Hz",
            harmony: "95% Hòa âm",
            distance: "📍 Cách bạn 1.2 km"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntryFromUserDefaults()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntryFromUserDefaults()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getEntryFromUserDefaults() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.fatelink.app")
        let name = userDefaults?.string(forKey: "soulmate_name") ?? "Tri kỷ FateLink"
        let vibe = userDefaults?.string(forKey: "soulmate_vibe") ?? "Đang hòa âm tần số 432 Hz"
        let harmony = userDefaults?.string(forKey: "soulmate_harmony") ?? "95% Hòa âm"
        let distance = userDefaults?.string(forKey: "soulmate_distance") ?? "📍 Gần bạn"
        return SimpleEntry(date: Date(), name: name, vibe: vibe, harmony: harmony, distance: distance)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let name: String
    let vibe: String
    let harmony: String
    let distance: String
}

struct CosmicSoulmateGlanceWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Cosmic Deep Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.11, blue: 0.29),
                    Color(red: 0.06, green: 0.09, blue: 0.16)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    Text("✦ FATELINK 432Hz")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.65, green: 0.71, blue: 0.99))
                    Spacer()
                    Text(entry.harmony)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.93, green: 0.28, blue: 0.60),
                                    Color(red: 0.55, green: 0.36, blue: 0.96)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }

                Divider().background(Color(red: 0.20, green: 0.25, blue: 0.38))

                // Soulmate Info
                Text(entry.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.97, green: 0.98, blue: 0.99))
                    .lineLimit(1)

                Text(entry.vibe)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.80, green: 0.84, blue: 0.88))
                    .lineLimit(1)

                Spacer()

                // Footer
                HStack {
                    Text(entry.distance)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    Spacer()
                    Text("Kết nối ›")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.93, green: 0.28, blue: 0.60))
                }
            }
            .padding(14)
        }
        .widgetURL(URL(string: "fatelink://match"))
    }
}

struct CosmicSoulmateGlanceWidget: Widget {
    let kind: String = "CosmicSoulmateGlanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CosmicSoulmateGlanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tri kỷ FateLink")
        .description("Theo dõi tần số cảm xúc và tâm hồn đồng điệu gần bạn nhất.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
