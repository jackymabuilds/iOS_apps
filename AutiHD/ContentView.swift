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
    @State private var reminders = [Reminder]()  // Array of reminders
    @State private var isPresentingAddReminder = false  // To control the sheet
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(reminders) { reminder in
                        HStack {
                            // Checkbox
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .onTapGesture {
                                    // Toggle completion
                                    if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                                        reminders[index].isCompleted.toggle()
                                    }
                                }
                            
                            VStack(alignment: .leading) {
                                // Title
                                Text(reminder.title)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .strikethrough(reminder.isCompleted)
                                
                                // Description (if exists)
                                if let description = reminder.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2) // Limit the description to two lines
                                        .truncationMode(.tail) // Truncate if it's too long
                                }
                                
                                // Display the time
                                Text("Time: \(formattedTime(for: reminder.time))")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onDelete(perform: deleteReminder)  // Handle swipe-to-delete
                }
                .navigationTitle("Reminders")
                
                // Button to show the AddReminderView
                Button(action: {
                    isPresentingAddReminder.toggle()
                }) {
                    Text("Add Reminder")
                        .frame(width: 150)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(100)
                }
            }
            .sheet(isPresented: $isPresentingAddReminder) {
                AddReminderView(reminders: $reminders)  // Pass the reminder list to the AddReminderView
            }
        }
        .onAppear {
            // Request notification permission when the view appears
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                } else {
                    print("Notification permission granted: \(granted)")
                }
            }
        }
    }

    // Function to delete a reminder
    func deleteReminder(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)  // Remove the reminder at the given index
    }

    // Function to format the time for display
    func formattedTime(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}

// struct to represent a reminder
struct Reminder: Identifiable {
    let id = UUID()
    var title: String
    var description: String?
    var isCompleted: Bool
    var time: Date
    var isRepeating: Bool  // New property to indicate if the reminder is recurring
}

struct AddReminderView: View {
    @Binding var reminders: [Reminder]  // To modify the list in the parent view
    @Environment(\.dismiss) var dismiss  // To dismiss the sheet
    
    @State private var newReminderTitle: String = ""  // User input for the title
    @State private var newReminderDescription: String = ""  // User input for the description
    @State private var reminderTime: Date = Date()  // Time for the reminder
    @State private var isRepeating: Bool = false  // New state to track the repeating option
    
    var body: some View {
        NavigationView {
            VStack {
                // Reminder Title Field
                VStack(alignment: .leading) {
                    Text("Reminder Title")
                        .font(.headline)
                    TextField("Enter title", text: $newReminderTitle)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                        .padding(.bottom)
                        .autocapitalization(.words)  // Capitalize words for title
                        .keyboardType(.default)  // Ensure the keyboard shows up properly
                }
                
                // Description Field
                VStack(alignment: .leading) {
                    Text("Description (Optional)")
                        .font(.headline)
                    TextField("Enter description (optional)", text: $newReminderDescription)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                        .padding(.bottom)
                        .autocapitalization(.sentences)  // Auto-capitalize first letter for description
                        .keyboardType(.default)  // Ensure keyboard
                }
                
                // Repeating Option
                Toggle("Repeat every 10 minutes", isOn: $isRepeating)
                    .padding()
                
                // Reminder Time Picker (with date and time when not repeating)
                if !isRepeating {
                    VStack(alignment: .leading) {
                        Text("Set Reminder Date & Time")
                            .font(.headline)
                        DatePicker("Select date/time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                            .padding()
                            .disabled(isRepeating)  // Disable the time picker if repeating
                    }
                } else {
                    Text("Reminder will repeat every 10 minutes.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                
                // Save Reminder Button
                Button(action: {
                    guard !newReminderTitle.isEmpty else { return }
                    
                    // Create new reminder with title, description, time, and repeating option
                    let newReminder = Reminder(
                        title: newReminderTitle,
                        description: newReminderDescription.isEmpty ? nil : newReminderDescription, // Only save description if not empty
                        isCompleted: false,
                        time: reminderTime,
                        isRepeating: isRepeating  // Pass the repeating option
                    )
                    reminders.append(newReminder)  // Append the new reminder to the list
                    scheduleNotification(for: newReminder)  // Schedule the notification
                    dismiss()  // Dismiss the AddReminderView
                }) {
                    Text("Save Reminder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newReminderTitle.isEmpty)  // Disable if the title is empty
            }
            .navigationTitle("Add Reminder")
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()  // Close without saving
            })
        }
    }
    
    // Function to schedule a local notification
    func scheduleNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.description ?? "Don't forget your reminder!"
        content.sound = .default
        
        if reminder.isRepeating {
            // For repeating reminders, we need to set up a trigger to repeat every 10 minutes
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: true) // 600 seconds = 10 minutes
            let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling repeating notification: \(error.localizedDescription)")
                } else {
                    print("Repeating notification scheduled for \(reminder.title)")
                }
            }
        } else {
            // For non-repeating reminders, set a one-time notification trigger
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
            
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

