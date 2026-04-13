import SwiftUI

// MARK: - Metric Card
struct MetricCard: View {
    let metric: HealthMetric
    
    var statusColor: Color {
        switch metric.status {
        case .normal: return .byg_success
        case .watch: return .byg_caution
        case .concerning: return .byg_urgent
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: metric.type.icon)
                    .font(.title3)
                    .foregroundColor(statusColor)
                Spacer()
                Image(systemName: metric.trend.icon)
                    .font(.caption)
                    .foregroundColor(.byg_textSecondary)
            }
            
            Text(formattedValue)
                .font(.title2.bold())
                .foregroundColor(.byg_textPrimary)
            
            Text(metric.type.rawValue)
                .font(.caption)
                .foregroundColor(.byg_textSecondary)
        }
        .bygCard()
    }
    
    var formattedValue: String {
        switch metric.type {
        case .steps: return "\(Int(metric.value))"
        case .sleep: return String(format: "%.1f", metric.value)
        default: return "\(Int(metric.value))"
        }
    }
}

// MARK: - Appointment Card
struct AppointmentCard: View {
    let appointment: Appointment
    var onPrepare: (() -> Void)? = nil
    var onPostVisit: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.doctorName)
                        .font(.headline)
                        .foregroundColor(.byg_textPrimary)
                    Text(appointment.specialty)
                        .font(.subheadline)
                        .foregroundColor(.byg_textSecondary)
                }
                Spacer()
                if !appointment.isCompleted {
                    CountdownBadge(days: appointment.daysUntil)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.byg_success)
                        .font(.title3)
                }
            }
            
            Divider()
            
            HStack(spacing: 16) {
                Label(appointment.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                Label(appointment.time, systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.byg_textSecondary)
            
            if !appointment.reason.isEmpty {
                Text(appointment.reason)
                    .font(.subheadline)
                    .foregroundColor(.byg_textSecondary)
                    .lineLimit(2)
            }
            
            // Action buttons
            if !appointment.isCompleted {
                if appointment.isWithinPrepWindow {
                    Button(action: { onPrepare?() }) {
                        Label("Prepare for Visit", systemImage: "doc.text.magnifyingglass")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.byg_primary)
                            .cornerRadius(10)
                    }
                }
            } else if appointment.postVisitSummary == nil {
                Button(action: { onPostVisit?() }) {
                    Label("Upload Visit Summary", systemImage: "camera.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.byg_primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.byg_primary.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .bygCard()
    }
}

// MARK: - Countdown Badge
struct CountdownBadge: View {
    let days: Int
    
    var body: some View {
        Text(days == 0 ? "Today" : "\(days)d")
            .font(.caption.bold())
            .foregroundColor(days <= 2 ? .byg_urgent : .byg_primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(days <= 2 ? Color.byg_urgent.opacity(0.12) : Color.byg_primary.opacity(0.12))
            )
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: AIInsight
    
    var accentColor: Color {
        switch insight.accentColor {
        case "green": return .byg_success
        case "yellow": return .byg_caution
        case "red": return .byg_urgent
        default: return .byg_primary
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.12))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.byg_textPrimary)
                Text(insight.body)
                    .font(.caption)
                    .foregroundColor(.byg_textSecondary)
                    .lineLimit(2)
            }
        }
        .bygCard()
    }
}

// MARK: - Provider Card
struct ProviderCard: View {
    let provider: Provider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .font(.headline)
                        .foregroundColor(.byg_textPrimary)
                    Text(provider.specialty)
                        .font(.subheadline)
                        .foregroundColor(.byg_textSecondary)
                }
                Spacer()
                if provider.acceptsInsurance {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.byg_success)
                }
            }
            
            HStack(spacing: 16) {
                Label(String(format: "%.1f mi", provider.distance), systemImage: "location.fill")
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.byg_caution)
                    Text(String(format: "%.1f", provider.rating))
                }
            }
            .font(.subheadline)
            .foregroundColor(.byg_textSecondary)
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Label("Directions", systemImage: "map.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.byg_primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.byg_primary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Label("Call", systemImage: "phone.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.byg_success)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.byg_success.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .bygCard()
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .byg_textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.role == .user ? Color.byg_primary : Color.byg_secondaryBg)
                    )
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.byg_textTertiary)
            }
            
            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.byg_textTertiary)
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.byg_textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.byg_textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
