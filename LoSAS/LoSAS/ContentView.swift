import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var mqttManager = MQTTManager()
    @State private var showClearConfirmation = false
    @State private var animateBackground = false

    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Animated Background
                ZStack {
                    LinearGradient(
                        colors: [Color.black, Color.gray.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [Color.purple.opacity(0.35), Color.clear],
                        center: animateBackground ? .topLeading : .bottomTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animateBackground)

                    RadialGradient(
                        colors: [Color.blue.opacity(0.25), Color.clear],
                        center: animateBackground ? .bottomTrailing : .topLeading,
                        startRadius: 50,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 25).repeatForever(autoreverses: true), value: animateBackground)

                    Color.white.opacity(0.01)
                        .blendMode(.overlay)
                        .ignoresSafeArea()
                }
                .onAppear {
                    animateBackground.toggle()
                }

                VStack(spacing: 20) {
                    // MARK: - Connection Status Indicator
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(mqttManager.isConnected ? Color.green : Color.red)
                                .frame(width: 20, height: 20)
                                .shadow(color: mqttManager.isConnected ? Color.green.opacity(0.7) : Color.red.opacity(0.7), radius: 8)

                            if mqttManager.isConnected {
                                Circle()
                                    .stroke(Color.green.opacity(0.5), lineWidth: 4)
                                    .frame(width: 28, height: 28)
                                    .blur(radius: 4)
                                    .scaleEffect(1.1)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: mqttManager.isConnected)
                            }
                        }

                        Text(mqttManager.isConnected ? "Connected" : "Disconnected")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 2)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(mqttManager.isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(mqttManager.isConnected ? Color.green.opacity(0.6) : Color.red.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: mqttManager.isConnected ? Color.green.opacity(0.4) : Color.red.opacity(0.3), radius: 6)
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.5), value: mqttManager.isConnected)

                    // MARK: - Clear Messages Button
                    if !mqttManager.messages.isEmpty {
                        Button(role: .destructive) {
                            withAnimation {
                                showClearConfirmation = true
                            }
                        } label: {
                            Label("Clear All Messages", systemImage: "trash")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                                .shadow(color: .red.opacity(0.5), radius: 6, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.4), value: mqttManager.messages)
                        .confirmationDialog("Are you sure you want to delete all messages?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                            Button("Delete All", role: .destructive) {
                                withAnimation(.spring()) {
                                    mqttManager.messages.removeAll()
                                }
                                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                    .appendingPathComponent("mqtt_messages.json")
                                try? FileManager.default.removeItem(at: url)
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                    }

                    // MARK: - Message Display
                    if mqttManager.messages.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.6))

                            Text("Waiting for messages...")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 100)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeInOut(duration: 0.5), value: mqttManager.messages)
                    } else {
                        ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(mqttManager.messages.reversed()) { item in
                                        NavigationLink(destination: MapView()) {
                                            MessageCardWideDark(item: item)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.6), value: mqttManager.messages.count)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Safety Dashboard")
            .foregroundColor(.white)
        }
        .preferredColorScheme(.dark)
    }
}

struct MessageCardWideDark: View {
    let item: LoSASMessageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("[\(item.topic)]")
                    .font(.caption)
                    .foregroundColor(.mint)
                Spacer()
                Text(item.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Text(item.message)
                .font(.headline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial) // frosted glass effect
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mint.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
        .transition(.scale.combined(with: .opacity))
    }
}

//import SwiftUI
//import MapKit
//
//struct ContentView: View {
//    @StateObject private var mqttManager = MQTTManager()
//    @State private var showClearConfirmation = false
//    @State private var animateBackground = false
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                AnimatedBackground(animateBackground: $animateBackground)
//
//                VStack(spacing: 20) {
//                    ConnectionStatusView(isConnected: mqttManager.isConnected)
//
//                    if !mqttManager.messages.isEmpty {
//                        ClearMessagesButton(showClearConfirmation: $showClearConfirmation) {
//                            clearMessages()
//                        }
//                    }
//
//                    MessageSection(messages: mqttManager.messages)
//                }
//                .padding(.top)
//            }
//            .navigationTitle("Safety Dashboard")
//            .foregroundColor(.white)
//        }
//        .onAppear {
//            animateBackground = true
//            mqttManager.connect() // ✅ Auto connect to MQTT on app open
//        }
//        .preferredColorScheme(.dark)
//    }
//
//    // MARK: - Clear all messages handler
//    private func clearMessages() {
//        withAnimation(.spring()) {
//            mqttManager.messages.removeAll()
//        }
//        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            .appendingPathComponent("mqtt_messages.json")
//        try? FileManager.default.removeItem(at: url)
//    }
//}
//
//// MARK: - Animated Background
//struct AnimatedBackground: View {
//    @Binding var animateBackground: Bool
//
//    var body: some View {
//        ZStack {
//            LinearGradient(
//                colors: [Color.black, Color.gray.opacity(0.15)],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
//
//            RadialGradient(
//                colors: [Color.purple.opacity(0.35), Color.clear],
//                center: animateBackground ? .topLeading : .bottomTrailing,
//                startRadius: 50,
//                endRadius: 400
//            )
//            .ignoresSafeArea()
//            .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animateBackground)
//
//            RadialGradient(
//                colors: [Color.blue.opacity(0.25), Color.clear],
//                center: animateBackground ? .bottomTrailing : .topLeading,
//                startRadius: 50,
//                endRadius: 500
//            )
//            .ignoresSafeArea()
//            .animation(.easeInOut(duration: 25).repeatForever(autoreverses: true), value: animateBackground)
//
//            Color.white.opacity(0.01)
//                .blendMode(.overlay)
//                .ignoresSafeArea()
//        }
//    }
//}
//
//// MARK: - Connection Status View
//struct ConnectionStatusView: View {
//    let isConnected: Bool
//
//    var body: some View {
//        HStack(spacing: 12) {
//            StatusCircle(isConnected: isConnected)
//
//            Text(isConnected ? "Connected" : "Disconnected")
//                .font(.headline)
//                .foregroundColor(.white)
//                .shadow(color: .black.opacity(0.6), radius: 2)
//
//            Spacer()
//        }
//        .padding(.vertical, 10)
//        .padding(.horizontal, 16)
//        .background(
//            RoundedRectangle(cornerRadius: 25)
//                .fill(isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 25)
//                .stroke(isConnected ? Color.green.opacity(0.6) : Color.red.opacity(0.6), lineWidth: 1)
//        )
//        .shadow(color: isConnected ? Color.green.opacity(0.4) : Color.red.opacity(0.3), radius: 6)
//        .padding(.horizontal)
//        .animation(.easeInOut(duration: 0.5), value: isConnected)
//    }
//}
//
//struct StatusCircle: View {
//    let isConnected: Bool
//
//    var body: some View {
//        ZStack {
//            Circle()
//                .fill(isConnected ? Color.green : Color.red)
//                .frame(width: 20, height: 20)
//                .shadow(color: isConnected ? Color.green.opacity(0.7) : Color.red.opacity(0.7), radius: 8)
//
//            if isConnected {
//                Circle()
//                    .stroke(Color.green.opacity(0.5), lineWidth: 4)
//                    .frame(width: 28, height: 28)
//                    .blur(radius: 4)
//                    .scaleEffect(1.1)
//                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isConnected)
//            }
//        }
//    }
//}
//
//// MARK: - Clear Button
//struct ClearMessagesButton: View {
//    @Binding var showClearConfirmation: Bool
//    let onClear: () -> Void
//
//    var body: some View {
//        Button(role: .destructive) {
//            withAnimation {
//                showClearConfirmation = true
//            }
//        } label: {
//            Label("Clear All Messages", systemImage: "trash")
//                .font(.subheadline)
//                .foregroundColor(.white)
//                .padding(12)
//                .frame(maxWidth: .infinity)
//                .background(Color.red.opacity(0.8))
//                .cornerRadius(12)
//                .shadow(color: .red.opacity(0.5), radius: 6, x: 0, y: 4)
//        }
//        .padding(.horizontal)
//        .transition(.opacity.combined(with: .move(edge: .top)))
//        .animation(.easeInOut(duration: 0.4), value: showClearConfirmation)
//        .confirmationDialog(
//            "Are you sure you want to delete all messages?",
//            isPresented: $showClearConfirmation,
//            titleVisibility: .visible
//        ) {
//            Button("Delete All", role: .destructive, action: onClear)
//            Button("Cancel", role: .cancel) {}
//        }
//    }
//}
//
//// MARK: - Message Section
//struct MessageSection: View {
//    let messages: [LoSASMessageItem]
//
//    var body: some View {
//        Group {
//            if messages.isEmpty {
//                VStack(spacing: 10) {
//                    Image(systemName: "antenna.radiowaves.left.and.right")
//                        .font(.system(size: 50))
//                        .foregroundColor(.gray.opacity(0.6))
//                    Text("Waiting for messages...")
//                        .font(.headline)
//                        .foregroundColor(.gray)
//                }
//                .padding(.top, 100)
//                .transition(.opacity)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 16) {
//                        ForEach(messages.reversed()) { item in
//                            NavigationLink(destination: MapView()) {
//                                MessageCardWideDark(item: item)
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.bottom, 20)
//                }
//                .transition(.opacity)
//            }
//        }
//        .animation(.easeInOut(duration: 0.6), value: messages.count)
//    }
//}
//
//// MARK: - Message Card
//struct MessageCardWideDark: View {
//    let item: LoSASMessageItem
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text("[\(item.topic)]")
//                    .font(.caption)
//                    .foregroundColor(.mint)
//                Spacer()
//                Text(item.timestamp, style: .time)
//                    .font(.caption2)
//                    .foregroundColor(.gray)
//            }
//
//            Text(item.message)
//                .font(.headline)
//                .foregroundColor(.white)
//                .fixedSize(horizontal: false, vertical: true)
//        }
//        .padding()
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(.ultraThinMaterial)
//        .cornerRadius(16)
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(Color.mint.opacity(0.5), lineWidth: 1)
//        )
//        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
//        .transition(.scale.combined(with: .opacity))
//    }
//}
//
