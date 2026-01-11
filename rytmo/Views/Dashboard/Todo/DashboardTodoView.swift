//
//  DashboardTodoView.swift
//  rytmo
//
//  Created by Sisyphus on 1/12/26.
//

import SwiftUI
import SwiftData

struct DashboardTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]

    @State private var showCreateSheet: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Tasks")
                            .font(.system(size: 28, weight: .bold))

                        Text("Manage your focus goals here.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        showCreateSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("New Task")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 40)

                // Content Section
                TodoListView(showHeader: false, compact: false)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .frame(maxWidth: 800)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showCreateSheet) {
            TodoCreateSheet()
        }
    }
}

// MARK: - Todo Create Sheet

private struct TodoCreateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date? = nil
    @State private var showDatePicker: Bool = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("New Task")
                    .font(.system(size: 20, weight: .bold))

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField("What needs to be done?", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .medium))
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                            .focused($isTitleFocused)
                            .onAppear {
                                isTitleFocused = true
                            }
                    }

                    // Description Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        TextEditor(text: $notes)
                            .font(.system(size: 14))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }

                    // Due Date Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            if let selectedDate = dueDate {
                                Button(action: {
                                    showDatePicker.toggle()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))

                                        Text(formatDate(selectedDate))
                                            .font(.system(size: 14))

                                        Spacer()

                                        Button(action: {
                                            dueDate = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(12)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    showDatePicker.toggle()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)

                                        Text("Set due date")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)

                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if showDatePicker {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { dueDate ?? Date() },
                                    set: { dueDate = $0 }
                                ),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .transition(.opacity)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: createTodo) {
                    HStack(spacing: 6) {
                        Text("Create Task")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func createTodo() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newTodo = TodoItem(
            title: title,
            notes: notes,
            dueDate: dueDate
        )
        modelContext.insert(newTodo)
        dismiss()
    }
}

#Preview {
    DashboardTodoView()
        .modelContainer(for: TodoItem.self, inMemory: true)
        .frame(width: 800, height: 600)
}
