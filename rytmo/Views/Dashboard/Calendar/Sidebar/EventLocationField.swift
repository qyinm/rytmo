import MapKit
import SwiftUI

struct EventLocationField: View {
    @Binding var location: String
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var locationSearchManager = LocationSearchManager()
    @FocusState private var isFocused: Bool
    @State private var showResults = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack(alignment: .topLeading) {
                TextField("Add Location", text: $location)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .focused($isFocused)
                    .onChange(of: location) { _, newValue in
                        locationSearchManager.queryFragment = newValue
                        showResults = !newValue.isEmpty
                    }

                if isFocused && showResults && !locationSearchManager.results.isEmpty {
                    resultList
                        .offset(y: 35)
                        .zIndex(10)
                }
            }
            .zIndex(10)
        }
        .zIndex(10)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(locationSearchManager.results, id: \.self) { result in
                    Button {
                        location = result.title
                        showResults = false
                        isFocused = false
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 200)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
        .cornerRadius(6)
        .shadow(radius: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
