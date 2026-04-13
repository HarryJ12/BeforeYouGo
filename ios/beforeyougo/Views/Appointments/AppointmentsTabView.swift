import SwiftUI
import Combine

// MARK: - Appointments Tab
struct AppointmentsTabView: View {
    @EnvironmentObject var appointmentVM: AppointmentViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    @EnvironmentObject var healthVM: HealthViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Upcoming
                    if !appointmentVM.upcomingAppointments.isEmpty {
                        BYGSectionHeader(title: "Upcoming")
                        ForEach(appointmentVM.upcomingAppointments) { appt in
                            AppointmentCard(
                                appointment: appt,
                                onPrepare: {
                                    appointmentVM.selectedAppointment = appt
                                    Task {
                                        await appointmentVM.generatePrep(
                                            for: appt,
                                            healthManager: HealthKitManager.shared,
                                            journalEntries: journalVM.entries,
                                            medications: [],
                                            conditions: []
                                        )
                                        appointmentVM.showPrepView = true
                                    }
                                }
                            )
                        }
                    }
                    
                    // Past
                    if !appointmentVM.pastAppointments.isEmpty {
                        BYGSectionHeader(title: "Past Visits")
                        ForEach(appointmentVM.pastAppointments) { appt in
                            AppointmentCard(
                                appointment: appt,
                                onPostVisit: {
                                    appointmentVM.selectedAppointment = appt
                                    appointmentVM.showPostVisitSheet = true
                                }
                            )
                            .onTapGesture {
                                if appt.postVisitSummary != nil {
                                    appointmentVM.selectedAppointment = appt
                                }
                            }
                        }
                    }
                    
                    if appointmentVM.appointments.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.plus",
                            title: "No Appointments",
                            message: "Add your upcoming doctor visits to get AI-powered preparation."
                        )
                    }
                }
                .padding()
            }
            .background(Color.byg_background)
            .navigationTitle("Appointments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { appointmentVM.showAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.byg_primary)
                    }
                }
            }
            .sheet(isPresented: $appointmentVM.showAddSheet) {
                AddAppointmentSheet()
                    .environmentObject(appointmentVM)
            }
            .sheet(isPresented: $appointmentVM.showPrepView) {
                if let appt = appointmentVM.selectedAppointment {
                    AppointmentPrepView(appointment: appt)
                        .environmentObject(appointmentVM)
                }
            }
            .sheet(isPresented: $appointmentVM.showPostVisitSheet) {
                if let appt = appointmentVM.selectedAppointment {
                    PostVisitUploadView(appointment: appt)
                        .environmentObject(appointmentVM)
                }
            }
        }
    }
}

// MARK: - Add Appointment Sheet
struct AddAppointmentSheet: View {
    @EnvironmentObject var appointmentVM: AppointmentViewModel
    @Environment(\.dismiss) var dismiss
    
    let timeOptions = ["8:00 AM", "8:30 AM", "9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM",
                       "11:00 AM", "11:30 AM", "12:00 PM", "12:30 PM", "1:00 PM", "1:30 PM",
                       "2:00 PM", "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Doctor") {
                    TextField("Doctor's name", text: $appointmentVM.newDoctorName)
                    TextField("Specialty (e.g., Primary Care)", text: $appointmentVM.newSpecialty)
                }
                
                Section("When") {
                    DatePicker("Date", selection: $appointmentVM.newDate, in: Date()..., displayedComponents: .date)
                    Picker("Time", selection: $appointmentVM.newTime) {
                        ForEach(timeOptions, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                }
                
                Section("Details") {
                    TextField("Reason for visit", text: $appointmentVM.newReason)
                    TextField("Location (optional)", text: $appointmentVM.newLocation)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        appointmentVM.addAppointment()
                        dismiss()
                    }
                    .disabled(appointmentVM.newDoctorName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Appointment Prep View (KEY FEATURE)
struct AppointmentPrepView: View {
    let appointment: Appointment
    @EnvironmentObject var appointmentVM: AppointmentViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "stethoscope")
                                .font(.title2)
                                .foregroundColor(.byg_primary)
                            Text(appointment.doctorName)
                                .font(.title2.bold())
                                .foregroundColor(.byg_textPrimary)
                        }
                        
                        HStack(spacing: 12) {
                            Label(appointment.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            Label(appointment.time, systemImage: "clock")
                        }
                        .font(.subheadline)
                        .foregroundColor(.byg_textSecondary)
                        
                        if !appointment.reason.isEmpty {
                            Text(appointment.reason)
                                .font(.body)
                                .foregroundColor(.byg_textSecondary)
                        }
                    }
                    .bygCard()
                    
                    if appointmentVM.isGeneratingPrep {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.byg_primary)
                            Text("Preparing your visit guide...")
                                .font(.subheadline)
                                .foregroundColor(.byg_textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else if let prep = appointment.prep {
                        // What to Mention
                        prepSection(
                            title: "What to Mention",
                            icon: "list.clipboard.fill",
                            color: .byg_primary,
                            items: prep.whatToMention
                        )
                        
                        // Questions to Ask
                        prepSection(
                            title: "Questions to Ask",
                            icon: "questionmark.circle.fill",
                            color: .byg_accent,
                            items: prep.questionsToAsk
                        )
                        
                        // Summary
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Summary", systemImage: "doc.text.fill")
                                .font(.headline)
                                .foregroundColor(.byg_textPrimary)
                            Text(prep.summary)
                                .font(.body)
                                .foregroundColor(.byg_textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .bygCard()
                        
                        // Share button
                        ShareLink(
                            item: appointmentVM.exportPrepText(for: appointment),
                            subject: Text("Appointment Prep - \(appointment.doctorName)"),
                            message: Text("My appointment preparation for \(appointment.date.formatted(date: .long, time: .omitted))")
                        ) {
                            Label("Share Prep", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.byg_primary)
                                .cornerRadius(14)
                        }
                    }
                    
                    if let error = appointmentVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.byg_urgent)
                            .padding()
                    }
                }
                .padding()
            }
            .background(Color.byg_background)
            .navigationTitle("Visit Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Prep Section
    private func prepSection(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.byg_textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        Text(item)
                            .font(.body)
                            .foregroundColor(.byg_textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .bygCard()
    }
}

// MARK: - Post-Visit Upload View (KEY FEATURE)
struct PostVisitUploadView: View {
    let appointment: Appointment
    @EnvironmentObject var appointmentVM: AppointmentViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var manualText = ""
    @State private var useManualEntry = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.byg_primary)
                        
                        Text("Upload Your Visit Summary")
                            .font(.title3.bold())
                            .foregroundColor(.byg_textPrimary)
                        
                        Text("Take a photo of your visit summary or after-visit paperwork. We'll translate the medical jargon into plain language.")
                            .font(.subheadline)
                            .foregroundColor(.byg_textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    if appointmentVM.isProcessingOCR {
                        // Processing state
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.byg_primary)
                            Text("Reading and translating your summary...")
                                .font(.subheadline)
                                .foregroundColor(.byg_textSecondary)
                            
                            // Steps indicator
                            VStack(alignment: .leading, spacing: 8) {
                                ProcessingStep(label: "Scanning document", isComplete: true)
                                ProcessingStep(label: "Extracting text", isComplete: true)
                                ProcessingStep(label: "Translating to plain language", isComplete: false)
                            }
                            .padding()
                        }
                        .bygCard()
                    } else if let summary = appointment.postVisitSummary {
                        // Show translated results
                        translatedSummaryView(summary)
                    } else if let image = inputImage {
                        // Show captured image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                        
                        Button(action: {
                            Task {
                                await appointmentVM.processPostVisitImage(image, for: appointment)
                            }
                        }) {
                            Label("Translate This Summary", systemImage: "text.magnifyingglass")
                        }
                        .buttonStyle(BYGPrimaryButtonStyle())
                        
                        Button("Retake Photo") {
                            inputImage = nil
                            showImagePicker = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.byg_primary)
                    } else if useManualEntry {
                        // Manual text entry
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Paste or type your visit summary:")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.byg_textPrimary)
                            
                            TextEditor(text: $manualText)
                                .frame(minHeight: 150)
                                .padding(8)
                                .background(Color.byg_secondaryBg)
                                .cornerRadius(12)
                            
                            Button(action: {
                                guard !manualText.isEmpty else { return }
                                Task {
                                    let summary = try? await ClaudeAPIService.shared.translatePostVisitSummary(rawText: manualText)
                                    if let summary = summary,
                                       let index = appointmentVM.appointments.firstIndex(where: { $0.id == appointment.id }) {
                                        appointmentVM.appointments[index].postVisitSummary = summary
                                        appointmentVM.appointments[index].isCompleted = true
                                        appointmentVM.selectedAppointment = appointmentVM.appointments[index]
                                    }
                                }
                            }) {
                                Label("Translate", systemImage: "text.magnifyingglass")
                            }
                            .buttonStyle(BYGPrimaryButtonStyle())
                            .disabled(manualText.isEmpty)
                        }
                        
                        Button("Use Camera Instead") {
                            useManualEntry = false
                            showImagePicker = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.byg_primary)
                    } else {
                        // Capture options
                        VStack(spacing: 12) {
                            Button(action: { showImagePicker = true }) {
                                Label("Take Photo", systemImage: "camera.fill")
                            }
                            .buttonStyle(BYGPrimaryButtonStyle())
                            
                            Button(action: { useManualEntry = true }) {
                                Label("Type It Instead", systemImage: "keyboard")
                            }
                            .buttonStyle(BYGSecondaryButtonStyle())
                        }
                    }
                    
                    if let error = appointmentVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.byg_urgent)
                            .padding()
                    }
                }
                .padding()
            }
            .background(Color.byg_background)
            .navigationTitle("Visit Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage)
            }
        }
    }
    
    // MARK: - Translated Summary
    private func translatedSummaryView(_ summary: PostVisitSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // What Doctor Found
            summarySection(
                title: "What the Doctor Found",
                icon: "magnifyingglass",
                color: .byg_primary,
                content: summary.whatDoctorFound
            )
            
            // What This Means
            summarySection(
                title: "What This Means",
                icon: "lightbulb.fill",
                color: .byg_caution,
                content: summary.whatThisMeans
            )
            
            // What to Do
            summarySection(
                title: "What to Do",
                icon: "checklist",
                color: .byg_success,
                content: summary.whatToDo
            )
        }
    }
    
    private func summarySection(title: String, icon: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)
            
            Text(content)
                .font(.body)
                .foregroundColor(.byg_textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .bygCard()
    }
}

// MARK: - Processing Step
struct ProcessingStep: View {
    let label: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.byg_success)
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
            Text(label)
                .font(.subheadline)
                .foregroundColor(isComplete ? .byg_textSecondary : .byg_textPrimary)
        }
    }
}

// MARK: - Image Picker (UIKit wrapper)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // Use camera if available, otherwise photo library
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
