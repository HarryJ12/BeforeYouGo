import SwiftUI

struct CareTabView: View {
    @State private var searchText = ""
    @State private var selectedSpecialty = "All"
    @State private var maxDistance: Double = 25
    @State private var insuranceOnly = false
    @State private var providers: [Provider] = []
    @State private var isLoading = false
    
    let specialties = ["All", "Primary Care", "Cardiology", "Dermatology", "Sports Medicine", "Orthopedics", "Mental Health", "Ophthalmology"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search & Filters
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.byg_textTertiary)
                        TextField("Search providers...", text: $searchText)
                    }
                    .padding(12)
                    .background(Color.byg_secondaryBg)
                    .cornerRadius(12)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(specialties, id: \.self) { spec in
                                Text(spec)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(selectedSpecialty == spec ? .white : .byg_textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedSpecialty == spec ? Color.byg_primary : Color.byg_secondaryBg)
                                    )
                                    .onTapGesture { selectedSpecialty = spec }
                            }
                        }
                    }
                    
                    HStack {
                        Toggle("In-network only", isOn: $insuranceOnly)
                            .font(.subheadline)
                            .tint(.byg_primary)
                    }
                }
                .padding()
                .background(Color.byg_cardBg)
                
                // Results
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredProviders) { provider in
                            ProviderCard(provider: provider)
                        }
                        
                        if filteredProviders.isEmpty {
                            EmptyStateView(
                                icon: "stethoscope",
                                title: "Search for Providers",
                                message: "Find doctors and specialists near you that accept your insurance."
                            )
                        }
                    }
                    .padding()
                }
                .background(Color.byg_background)
            }
            .navigationTitle("Find Care")
            .task {
                loadMockProviders()
            }
        }
    }
    
    var filteredProviders: [Provider] {
        providers.filter { provider in
            let matchesSearch = searchText.isEmpty || provider.name.localizedCaseInsensitiveContains(searchText) || provider.specialty.localizedCaseInsensitiveContains(searchText)
            let matchesSpecialty = selectedSpecialty == "All" || provider.specialty == selectedSpecialty
            let matchesInsurance = !insuranceOnly || provider.acceptsInsurance
            let matchesDistance = provider.distance <= maxDistance
            return matchesSearch && matchesSpecialty && matchesInsurance && matchesDistance
        }
    }
    
    private func loadMockProviders() {
        providers = [
            Provider(name: "Dr. Sarah Chen", specialty: "Primary Care", distance: 2.3, rating: 4.8, acceptsInsurance: true, address: "145 Pawtucket St, Lowell, MA", phone: "(978) 555-0101"),
            Provider(name: "Dr. Michael Torres", specialty: "Sports Medicine", distance: 3.1, rating: 4.6, acceptsInsurance: true, address: "231 Chelmsford St, Lowell, MA", phone: "(978) 555-0102"),
            Provider(name: "Dr. Priya Patel", specialty: "Cardiology", distance: 5.7, rating: 4.9, acceptsInsurance: true, address: "50 Warren St, Lowell, MA", phone: "(978) 555-0103"),
            Provider(name: "Dr. James Liu", specialty: "Dermatology", distance: 4.2, rating: 4.5, acceptsInsurance: false, address: "300 Merrimack Ave, Lowell, MA", phone: "(978) 555-0104"),
            Provider(name: "Dr. Emily Walsh", specialty: "Mental Health", distance: 1.8, rating: 4.7, acceptsInsurance: true, address: "100 University Ave, Lowell, MA", phone: "(978) 555-0105"),
            Provider(name: "Dr. Robert Kim", specialty: "Orthopedics", distance: 8.5, rating: 4.4, acceptsInsurance: true, address: "15 Research Pl, N Chelmsford, MA", phone: "(978) 555-0106"),
        ]
    }
}
