import SwiftUI

struct EventTimeframeView: View {
    @Binding var startTime: Date
    @Binding var endTime: Date

    private let compactWheelHeight: CGFloat = 36
    private let pickerWidth: CGFloat = 120
    private let timePickerWidth: CGFloat = 64
    private let durationPickerWidth: CGFloat = 72
    private let clockSize: CGFloat = 176
    private let maxDurationDays = 99

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 14) {
//                  DatePicker("StartDate", selection: $startTime, displayedComponents: .date)
//                    .labelsHidden()
                    labeledWheel("Start") {
                      VStack(alignment: .leading) {
                      DatePicker("StartDate", selection: $startTime, displayedComponents: .date)
                        .labelsHidden()
                        compactWheel(width: pickerWidth) {
                            timeWheel(selection: $startTime)
                        }
                       }
//                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    labeledWheel("End") {
                      VStack {
                        DatePicker("EndDate", selection: $endTime, displayedComponents: .date)
                          .labelsHidden()
                        compactWheel(width: pickerWidth) {
                          timeWheel(selection: $endTime)
                        }
                      }
//                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    ClockView(duration: duration, startTime: startTime)
                        .frame(width: clockSize, height: clockSize)
                  
                  labeledWheel("Duration") {
                      HStack(spacing: 0) {
                          compactWheel(width: durationPickerWidth) {
                              Picker("Days", selection: durationDays) {
                                  ForEach(0...maxDurationDays, id: \.self) { value in
                                      durationText(value, unit: "d")
                                          .tag(value)
                                  }
                              }
                              .pickerStyle(.wheel)
                              .labelsHidden()
                          }

                          compactWheel(width: durationPickerWidth) {
                              Picker("Hours", selection: durationHours) {
                                  ForEach(0..<24) { value in
                                      durationText(value, unit: "h")
                                          .tag(value)
                                  }
                              }
                              .pickerStyle(.wheel)
                              .labelsHidden()
                          }

                          compactWheel(width: durationPickerWidth) {
                              Picker("Minutes", selection: durationMinutes) {
                                  ForEach(0..<60) { value in
                                      durationText(value, unit: "m")
                                          .tag(value)
                                  }
                              }
                              .pickerStyle(.wheel)
                              .labelsHidden()
                          }
                      }
                      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                  }
                }
                .frame(width: clockSize + 24)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .onChange(of: startTime) { oldValue, newValue in
            adjustStartTime(from: oldValue, to: newValue)
        }
        .onChange(of: endTime) { _, _ in
            adjustEndTime()
        }
    }

    private var duration: Binding<TimeInterval> {
        Binding(
            get: { max(0, endTime.timeIntervalSince(startTime)) },
            set: { newValue in
                endTime = startTime.addingTimeInterval(max(0, newValue))
            }
        )
    }

    private var durationHours: Binding<Int> {
        Binding(
            get: { (totalDurationMinutes / 60) % 24 },
            set: { newValue in
                updateDuration(
                    days: durationDays.wrappedValue,
                    hours: newValue,
                    minutes: durationMinutes.wrappedValue
                )
            }
        )
    }

    private var durationMinutes: Binding<Int> {
        Binding(
            get: { totalDurationMinutes % 60 },
            set: { newValue in
                updateDuration(
                    days: durationDays.wrappedValue,
                    hours: durationHours.wrappedValue,
                    minutes: newValue
                )
            }
        )
    }

    private var durationDays: Binding<Int> {
        Binding(
            get: { min(maxDurationDays, totalDurationMinutes / (24 * 60)) },
            set: { newValue in
                updateDuration(
                    days: newValue,
                    hours: durationHours.wrappedValue,
                    minutes: durationMinutes.wrappedValue
                )
            }
        )
    }

    private var totalDurationMinutes: Int {
        max(0, Int(duration.wrappedValue) / 60)
    }

    private func labeledWheel<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func compactWheel<Content: View>(
        width: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            content()
        }
        .frame(width: width, height: compactWheelHeight)
        .clipped()
        .contentShape(Rectangle())
        .fixedSize(horizontal: true, vertical: false)
    }

    private func timeWheel(selection: Binding<Date>) -> some View {
        HStack(spacing: 0) {
            compactWheel(width: timePickerWidth) {
                Picker("Hours", selection: hourBinding(for: selection)) {
                    ForEach(0..<24, id: \.self) { value in
                        timeText(value)
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }

            timeSeparator()

            compactWheel(width: timePickerWidth) {
                Picker("Minutes", selection: minuteBinding(for: selection)) {
                    ForEach(0..<60, id: \.self) { value in
                        timeText(value)
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }
        }
    }

    private func durationText(_ value: Int, unit: String) -> some View {
        Text("\(value)\(unit)")
            .font(.body)
            .monospacedDigit()
    }

    private func timeText(_ value: Int) -> some View {
        Text(value.formatted(.number.precision(.integerLength(2))))
            .font(.body)
            .monospacedDigit()
    }

    private func timeSeparator() -> some View {
        Text(":")
            .font(.title3.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 10)
            .allowsHitTesting(false)
    }

    private func hourBinding(for selection: Binding<Date>) -> Binding<Int> {
        Binding(
            get: { Calendar.current.component(.hour, from: selection.wrappedValue) },
            set: { newValue in
                selection.wrappedValue = dateBySetting(
                    hour: newValue,
                    minute: Calendar.current.component(.minute, from: selection.wrappedValue),
                    on: selection.wrappedValue
                )
            }
        )
    }

    private func minuteBinding(for selection: Binding<Date>) -> Binding<Int> {
        Binding(
            get: { Calendar.current.component(.minute, from: selection.wrappedValue) },
            set: { newValue in
                selection.wrappedValue = dateBySetting(
                    hour: Calendar.current.component(.hour, from: selection.wrappedValue),
                    minute: newValue,
                    on: selection.wrappedValue
                )
            }
        )
    }

    private func dateBySetting(hour: Int, minute: Int, on date: Date) -> Date {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let components = DateComponents(
            year: currentComponents.year,
            month: currentComponents.month,
            day: currentComponents.day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components) ?? date
    }

    private func adjustStartTime(from oldValue: Date, to newValue: Date) {
        let delta = newValue.timeIntervalSince(oldValue)
        endTime = endTime.addingTimeInterval(delta)
    }

    private func adjustEndTime() {
        endTime = max(endTime, startTime)
    }

    private func updateDuration(days: Int, hours: Int, minutes: Int) {
        let totalMinutes = max(0, (days * 24 * 60) + (hours * 60) + minutes)
        let totalSeconds = totalMinutes * 60
        duration.wrappedValue = TimeInterval(totalSeconds)
    }
}

#Preview {
    PreviewContainer()
}

private struct PreviewContainer: View {
    @State private var startTime = Date.now
    @State private var endTime = Date.now + 3600

    var body: some View {
        EventTimeframeView(
            startTime: $startTime,
            endTime: $endTime
        )
    }
}
