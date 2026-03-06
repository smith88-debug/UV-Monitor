import SwiftUI
import Charts

struct UVChartView: View {
    let forecast: UVForecast?
    let measured: [UVForecastPoint]
    var stationTimeZone: TimeZone = .current

    private var chartStartHour: Int { 5 }
    private var chartEndHour: Int { 21 }

    private var xDomain: ClosedRange<Date> {
        // Use the station's timezone so forecast and measured data align on the
        // same local-time x-axis regardless of where the device is located.
        var cal = Calendar.current
        cal.timeZone = stationTimeZone
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .hour, value: chartStartHour, to: today)!
        let end = cal.date(byAdding: .hour, value: chartEndHour, to: today)!
        return start...end
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's UV")
                .font(.headline)

            Chart {
                // UV risk zone background bands
                uvZoneMark(low: 0, high: 3, color: .green)
                uvZoneMark(low: 3, high: 6, color: .yellow)
                uvZoneMark(low: 6, high: 8, color: .orange)
                uvZoneMark(low: 8, high: 11, color: .red)
                uvZoneMark(low: 11, high: 16, color: .purple)

                // Protection threshold line
                RuleMark(y: .value("Protection", 3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.gray.opacity(0.6))
                    .annotation(position: .topLeading, spacing: 2) {
                        Text("SPF")
                            .font(.system(size: 9))
                            .foregroundStyle(.gray)
                    }

                // Forecast line (dashed)
                if let forecast {
                    ForEach(forecast.points) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("UV", point.uvIndex),
                            series: .value("Type", "Predicted")
                        )
                        .foregroundStyle(.blue.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .interpolationMethod(.catmullRom)
                    }
                }

                // Measured line (solid)
                ForEach(measured) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("UV", point.uvIndex),
                        series: .value("Type", "Measured")
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }

                // Current time indicator
                RuleMark(x: .value("Now", Date()))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .chartXScale(domain: xDomain)
            .chartYScale(domain: 0...16)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 2)) { value in
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 3, 6, 8, 11, 14]) { value in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .frame(height: 220)

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .blue.opacity(0.7), label: "Predicted", dashed: true)
                LegendItem(color: .orange, label: "Measured", dashed: false)
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    @ChartContentBuilder
    private func uvZoneMark(low: Double, high: Double, color: Color) -> some ChartContent {
        RectangleMark(
            xStart: .value("Start", xDomain.lowerBound),
            xEnd: .value("End", xDomain.upperBound),
            yStart: .value("Low", low),
            yEnd: .value("High", high)
        )
        .foregroundStyle(color.opacity(0.08))
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    let dashed: Bool

    var body: some View {
        HStack(spacing: 4) {
            if dashed {
                DashedLine()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .frame(width: 20, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 20, height: 2)
            }
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
