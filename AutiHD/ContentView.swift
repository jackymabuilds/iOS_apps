//
//  ContentView.swift
//
//  Created by Jacky Ma on 8/3/25.
//

import UserNotifications
import SwiftUI

struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }

        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even if the app is in the foreground
        completionHandler([.banner, .sound]) // Use `.banner` for the updated way to display alerts
    }
}

struct ContentView: View {
    @State private var categories = [
        Category(name: "Appointments", reminders: []),
        Category(name: "Chores", reminders: []),
        Category(name: "Groceries", reminders: [])
    ]
    @State private var isPresentingAddReminder = false  // To control the sheet

    var body: some View {
        NavigationView {
            List {
                // Iterate over categories
                ForEach(categories) { category in
                    Section(header: Text(category.name)) {
                        // Display reminders in this category
                        ForEach(category.reminders) { reminder in
                            HStack {
                                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .onTapGesture {
                                        // Toggle completion
                                        toggleCompletion(for: reminder, in: category)
                                    }

                                VStack(alignment: .leading) {
                                    Text(reminder.title)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .strikethrough(reminder.isCompleted)
                                    
                                    if let description = reminder.description {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                    
                                    Text("Time: \(formattedTime(for: reminder.time))")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteReminder(at: indexSet, in: category)
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingAddReminder.toggle()
                    }) {
                        Text("Add Reminder")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddReminder) {
                AddReminderView(categories: $categories)
            }
        }
    }

    // Function to delete a reminder from a category
    func deleteReminder(at offsets: IndexSet, in category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].reminders.remove(atOffsets: offsets)
        }
    }

    // Function to toggle completion of a reminder
    func toggleCompletion(for reminder: Reminder, in category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            if let reminderIndex = categories[index].reminders.firstIndex(where: { $0.id == reminder.id }) {
                categories[index].reminders[reminderIndex].isCompleted.toggle()
            }
        }
    }

    // Function to format the time for display
    func formattedTime(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}

// struct to represent a reminder
struct Category: Identifiable {
    let id = UUID()
    var name: String
    var reminders: [Reminder]
}

struct Reminder: Identifiable {
    let id = UUID()
    var title: String
    var description: String?  // Optional description
    var isCompleted: Bool
    var time: Date  // New property to store the time for the reminder
    var category: String  // Category name, e.g., "Appointments", "Chores", etc.
    var isRepeating: Bool  // Flag for repeating every 10 minutes
}

struct AddReminderView: View {
    @Binding var categories: [Category]
    @Environment(\.dismiss) var dismiss

    @State private var newReminderTitle: String = ""
    @State private var newReminderDescription: String = ""
    @State private var reminderTime: Date = Date()
    @State private var selectedCategory: String = "Appointments"
    @State private var isRepeating: Bool = false  // Flag for repeating every 10 minutes

    var body: some View {
        NavigationView {
            VStack {
                // Category Picker (first selection option)
                VStack(alignment: .leading) {
                    Text("Select Category")
                        .font(.headline)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories.map { $0.name }, id: \.self) { categoryName in
                            Text(categoryName).tag(categoryName)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                }

                // Reminder Title Field
                VStack(alignment: .leading) {
                    Text("Reminder Title")
                        .font(.headline)
                    TextField("Enter title", text: $newReminderTitle)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                        .padding(.bottom)
                }

                // Description Field
                VStack(alignment: .leading) {
                    Text("Description (Optional)")
                        .font(.headline)
                    TextField("Enter description", text: $newReminderDescription)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                        .padding(.bottom)
                }

                // Repeating Option
                Toggle("Repeat every 10 minutes", isOn: $isRepeating)
                    .padding()

                // Reminder Time Picker
                VStack(alignment: .leading) {
                    Text("Set Reminder Date & Time")
                        .font(.headline)
                    DatePicker("Select time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                        .padding()
                        .disabled(isRepeating ? true : false)  // Disable time picker when repeating
                }

                // Save Button
                Button(action: {
                    guard !newReminderTitle.isEmpty else { return }
                    addReminder()
                    dismiss()
                }) {
                    Text("Save Reminder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newReminderTitle.isEmpty)
            }
            .navigationTitle("Add Reminder")
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }

    // Function to add a reminder
    func addReminder() {
        let newReminder = Reminder(
            title: newReminderTitle,
            description: newReminderDescription.isEmpty ? nil : newReminderDescription,
            isCompleted: false,
            time: reminderTime,
            category: selectedCategory,
            isRepeating: isRepeating  // Save the repeating option
        )

        // Find the category and append the new reminder
        if let index = categories.firstIndex(where: { $0.name == selectedCategory }) {
            categories[index].reminders.append(newReminder)
        }

        // Schedule notification if needed
        scheduleNotification(for: newReminder)
    }

    // Function to schedule a local notification for the reminder
    func scheduleNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.description ?? "Don't forget your reminder!"
        content.sound = .default

        if reminder.isRepeating {
            // Schedule the first notification once at the selected date and time
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
            
            // Add the first notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling first notification: \(error.localizedDescription)")
                } else {
                    print("First notification scheduled for \(reminder.title) at \(reminder.time)")
                }
            }

            // Schedule repeating notifications every 10 minutes
            var currentTriggerTime = reminder.time.addingTimeInterval(600)  // Start 10 minutes later
            let interval: TimeInterval = 600  // 600 seconds = 10 minutes
            
            for i in 1..<10 {  // Skip the first trigger, start from i=1
                currentTriggerTime = currentTriggerTime.addingTimeInterval(interval)
                let repeatingTrigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: currentTriggerTime), repeats: false)
                let repeatingRequest = UNNotificationRequest(identifier: "\(reminder.id.uuidString)-\(i)", content: content, trigger: repeatingTrigger)
                UNUserNotificationCenter.current().add(repeatingRequest) { error in
                    if let error = error {
                        print("Error scheduling repeating notification: \(error.localizedDescription)")
                    } else {
                        print("Repeating notification scheduled for \(reminder.title) at \(currentTriggerTime)")
                    }
                }
            }
        } else {
            // Schedule a single notification if not repeating
            let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.time), repeats: false))
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Notification scheduled for \(reminder.title) at \(reminder.time)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

