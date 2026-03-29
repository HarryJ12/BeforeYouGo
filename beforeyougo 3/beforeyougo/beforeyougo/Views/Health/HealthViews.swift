import SwiftUI
import Charts

// MARK: - HealthKit Tab
struct HealthKitTabView: View {
    @EnvironmentObject var healthVM: HealthViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(healthVM.metrics) { metric in
                            NavigationLink(destination: MetricDetailView(metric: metric)) {
                                MetricCard(metric: metric)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Insights
                    if !healthVM.insights.isEmpty {
                        BYGSectionHeader(title: "AI Insights")
                        ForEach(healthVM.insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding()
            }
            .background(Color.byg_background)
            .navigationTitle("Health")
            .refreshable {
                await healthVM.refreshMetrics()
            }
        }
    }
}

// MARK: - Metric Detail View
struct MetricDetailView: View {
    let metric: HealthMetric
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current Value
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: metric.type.icon)
                            .font(.title2)
                            .foregroundColor(statusColor)
                        Text(metric.type.rawValue)
                            .font(.title3.bold())
                            .foregroundColor(.byg_textPrimary)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formattedValue)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.byg_textPrimary)
                        Text(metric.unit)
                            .font(.title3)
                            .foregroundColor(.byg_textSecondary)
                        
                        Spacer()
                        
                        Image(systemName: metric.trend.icon)
                            .font(.title2)
                            .foregroundColor(.byg_textSecondary)
                    }
                }
                .bygCard()
                
                // Chart
                if !metric.history.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 Days")
                            .font(.headline)
                            .foregroundColor(.byg_textPrimary)
                        
                        Chart(metric.history) { point in
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(Color.byg_primary)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.byg_primary.opacity(0.2), Color.byg_primary.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(Color.byg_primary)
                            .symbolSize(30)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 200)
                    }
                    .bygCard()
                }
                
                // AI Explanation placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Label("What This Means", systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundColor(.byg_textPrimary)
                    
                    Text(explanationText)
                        .font(.body)
                        .foregroundColor(.byg_textSecondary)
                }
                .bygCard()
                
                // Add to Appointment Prep
                Button(action: {}) {
                    Label("Add to Appointment Prep", systemImage: "plus.circle.fill")
                }
                .buttonStyle(BYGSecondaryButtonStyle())
            }
            .padding()
        }
        .background(Color.byg_background)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var statusColor: Color {
        switch metric.status {
        case .normal: return .byg_success
        case .watch: return .byg_caution
        case .concerning: return .byg_urgent
        }
    }
    
    var formattedValue: String {
        switch metric.type {
        case .steps: return "\(Int(metric.value))"
        case .sleep: return String(format: "%.1f", metric.value)
        default: return "\(Int(metric.value))"
        }
    }
    
    var explanationText: String {
        switch metric.type {
        case .heartRate:
            return "Your resting heart rate is in the normal range (60-100 bpm). A lower resting heart rate generally indicates better cardiovascular fitness."
        case .steps:
            return "The recommended goal is 8,000-10,000 steps per day. You're \(metric.value >= 8000 ? "meeting" : "working toward") that target."
        case .sleep:
            return "Adults need 7-9 hours of sleep. You got \(String(format: "%.1f", metric.value)) hours last night, which is \(metric.value >= 7 ? "within the recommended range" : "below the recommended amount")."
        case .weight:
            return "Your weight has been relatively stable. Consistent tracking helps identify trends over time."
        case .bloodPressure:
            return "Normal blood pressure is below 120/80 mmHg. Regular monitoring helps catch changes early."
        }
    }
}

// MARK: - Journal Tab
struct JournalTabView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Start Check-In
                    Button(action: { journalVM.startCheckIn() }) {
                        HStack(spacing: 14) {
                            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start Daily Check-In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Chat with AI about your day")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [.byg_primary, .byg_primaryDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    
                    // Quick Log
                    QuickLogSection()
                        .environmentObject(journalVM)
                    
                    // Timeline
                    if !journalVM.entries.isEmpty {
                        BYGSectionHeader(title: "Health Timeline")
                        ForEach(journalVM.entries) { entry in
                            JournalEntryCard(entry: entry)
                        }
                    }
                }
                .padding()
            }
            .background(Color.byg_background)
            .navigationTitle("Health Journal")
            .sheet(isPresented: $journalVM.showChat) {
                JournalChatView()
                    .environmentObject(journalVM)
            }
        }
    }
}

// MARK: - Quick Log
struct QuickLogSection: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var selectedMood = ""
    @State private var selectedSymptoms: Set<String> = []
    
    let moods = ["😊", "😐", "😔", "😴", "💪", "🤒"]
    let moodLabels = ["Good", "Okay", "Down", "Tired", "Strong", "Sick"]
    let symptoms = ["Headache", "Fatigue", "Nausea", "Sore throat", "Back pain", "Congestion"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)
                .foregroundColor(.byg_textPrimary)
            
            // Mood picker
            HStack(spacing: 8) {
                ForEach(Array(zip(moods, moodLabels)), id: \.0) { emoji, label in
                    VStack(spacing: 4) {
                        Text(emoji)
                            .font(.title2)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(selectedMood == label ? Color.byg_primary.opacity(0.15) : Color.byg_secondaryBg)
                            )
                            .overlay(
                                Circle()
                                    .stroke(selectedMood == label ? Color.byg_primary : Color.clear, lineWidth: 2)
                            )
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(.byg_textSecondary)
                    }
                    .onTapGesture { selectedMood = label }
                }
            }
            
            // Symptom checkboxes
            FlowLayout(spacing: 8) {
                ForEach(symptoms, id: \.self) { symptom in
                    let isSelected = selectedSymptoms.contains(symptom)
                    Text(symptom)
                        .font(.caption.weight(.medium))
                        .foregroundColor(isSelected ? .white : .byg_textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.byg_primary : Color.byg_secondaryBg)
                        )
                        .onTapGesture {
                            if isSelected {
                                selectedSymptoms.remove(symptom)
                            } else {
                                selectedSymptoms.insert(symptom)
                            }
                        }
                }
            }
            
            if !selectedMood.isEmpty {
                Button(action: {
                    journalVM.quickLog(mood: selectedMood, symptoms: Array(selectedSymptoms))
                    selectedMood = ""
                    selectedSymptoms = []
                }) {
                    Text("Log It")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.byg_primary)
                        .cornerRadius(10)
                }
            }
        }
        .bygCard()
    }
}

// MARK: - Flow Layout (for symptom tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    let entry: JournalEntry
    
    var moodEmoji: String {
        switch entry.mood.lowercased() {
        case "great", "good": return "😊"
        case "fair", "okay": return "😐"
        case "poor", "bad": return "😔"
        default: return "📝"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(moodEmoji)
                    .font(.title2)
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.byg_textPrimary)
                Spacer()
                Text(entry.mood.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.byg_primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.byg_primary.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if !entry.aiSummary.isEmpty {
                Text(entry.aiSummary)
                    .font(.subheadline)
                    .foregroundColor(.byg_textSecondary)
                    .lineLimit(3)
            }
            
            if !entry.symptoms.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.symptoms, id: \.self) { symptom in
                        Text(symptom)
                            .font(.caption2)
                            .foregroundColor(.byg_caution)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.byg_caution.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .bygCard()
    }
}

// MARK: - Journal Chat View
struct JournalChatView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(journalVM.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if journalVM.isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: journalVM.messages.count) { _ in
                        if let last = journalVM.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input bar
                HStack(spacing: 12) {
                    TextField("Type your response...", text: $journalVM.currentInput, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(12)
                        .background(Color.byg_secondaryBg)
                        .cornerRadius(20)
                        .focused($isInputFocused)
                    
                    Button(action: {
                        Task { await journalVM.sendMessage() }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(journalVM.currentInput.isEmpty ? .byg_textTertiary : .byg_primary)
                    }
                    .disabled(journalVM.currentInput.isEmpty || journalVM.isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.byg_cardBg)
            }
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.byg_textTertiary)
                    .frame(width: 8, height: 8)
                    .offset(y: animating ? -5 : 0)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever()
                        .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.byg_secondaryBg)
        .cornerRadius(18)
        .onAppear { animating = true }
    }
}
