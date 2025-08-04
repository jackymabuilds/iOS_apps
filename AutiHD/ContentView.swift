//
//  ContentView.swift
//  testing
//
//  Created by Jacky Ma on 8/3/25.
//

import UserNotifications
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
        return true
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
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
    var description: String?  // Optional description
    var isCompleted: Bool
    var time: Date  // New property to store the time for the reminder
}

struct AddReminderView: View {
    @Binding var reminders: [Reminder]  // To modify the list in the parent view
    @Environment(\.dismiss) var dismiss  // To dismiss the sheet
    
    @State private var newReminderTitle: String = ""  // User input for the title
    @State private var newReminderDescription: String = ""  // User input for the description
    @State private var reminderTime: Date = Date()  // Time for the reminder
    
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
                
                // Reminder Time Picker
                VStack(alignment: .leading) {
                    Text("Set Reminder Time")
                        .font(.headline)
                    DatePicker("Select time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                        .padding()
                }
                
                // Save Reminder Button
                Button(action: {
                    guard !newReminderTitle.isEmpty else { return }
                    
                    // Create new reminder with title, description, and time
                    let newReminder = Reminder(
                        title: newReminderTitle,
                        description: newReminderDescription.isEmpty ? nil : newReminderDescription, // Only save description if not empty
                        isCompleted: false,
                        time: reminderTime
                    )
                    reminders.append(newReminder)  // Append the new reminder to the list
                    scheduleNotification(for: newReminder)  // Schedule the notification
                    dismiss()  // Dismiss the AddReminderView
                }) {
                    Text("Save Reminder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
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
        
        // Set the trigger time based on the reminder's time
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
