//
//  ContentView.swift
//  StringUI
//
//  Created by Aadi Shiv Malhotra on 11/28/24.
//

import SwiftUI

struct WireGrabberView: View {
    @State private var showCircleWebView = false // Toggle for the new view
    @State private var bottomNodes = [CGPoint](repeating: .zero, count: 3)
    @State private var topNodes = [CGPoint](repeating: .zero, count: 3)
    @State private var draggingPoint: CGPoint? = nil
    @State private var selectedNode: (isBottom: Bool, index: Int)? = nil

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Buttons
                HStack {
                    Button("Select Node") {
                        selectedNode = nil // Enables node selection
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Clear") {
                        selectedNode = nil
                        draggingPoint = nil // Clears selection and wire
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Open Circles View") {
                        showCircleWebView = true // Open the new view
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Spacer()

                // Wire Grabber UI
                ZStack {
                    // Bottom Nodes
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                            .overlay(
                                selectedNode?.isBottom == true && selectedNode?.index == index
                                    ? Color.green.opacity(0.3)
                                    : Color.clear
                            )
                            .position(getBottomNodePosition(for: index, in: geometry))
                            .onTapGesture {
                                if selectedNode == nil {
                                    selectedNode = (true, index) // Select this bottom node
                                }
                            }
                    }

                    // Top Nodes
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                            .overlay(
                                selectedNode?.isBottom == false && selectedNode?.index == index
                                    ? Color.green.opacity(0.3)
                                    : Color.clear
                            )
                            .position(getTopNodePosition(for: index, in: geometry))
                            .onTapGesture {
                                if selectedNode == nil {
                                    selectedNode = (false, index) // Select this top node
                                }
                            }
                    }

                    // Wire
                    if let draggingPoint = draggingPoint, let startNode = selectedNode {
                        let startPoint = startNode.isBottom
                            ? getBottomNodePosition(for: startNode.index, in: geometry)
                            : getTopNodePosition(for: startNode.index, in: geometry)

                        InteractiveWire(from: startPoint, to: draggingPoint)
                            .stroke(Color.gray, lineWidth: 3)
                            .animation(.spring(), value: draggingPoint)
                    }
                }
                .gesture(dragGesture(in: geometry))
                .onAppear {
                    setupNodes(in: geometry)
                }

                Spacer()
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showCircleWebView) {
            CircleWebView()
        }
    }

    // Helper Methods
    private func setupNodes(in geometry: GeometryProxy) {
        let width = geometry.size.width
        let height = geometry.size.height

        for i in 0..<3 {
            bottomNodes[i] = CGPoint(x: width * 0.2 + CGFloat(i) * width * 0.3, y: height * 0.9)
            topNodes[i] = CGPoint(x: width * 0.2 + CGFloat(i) * width * 0.3, y: height * 0.1)
        }
    }

    private func getBottomNodePosition(for index: Int, in geometry: GeometryProxy) -> CGPoint {
        bottomNodes[index]
    }

    private func getTopNodePosition(for index: Int, in geometry: GeometryProxy) -> CGPoint {
        topNodes[index]
    }

    private func dragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if selectedNode != nil {
                    draggingPoint = value.location
                }
            }
            .onEnded { _ in
                draggingPoint = nil
            }
    }
}
import SwiftUI

struct CircleWebView: View {
    @State private var circles: [Node] = [] // Circle positions and letters
    @State private var offset: CGSize = .zero // Cumulative offset for panning
    @State private var gestureOffset: CGSize = .zero // Temporary gesture offset
    @State private var selectedNode: Node? // Node selected for popup
    @State private var showPopup = false // Control popup display

    let circleCount = 30 // Number of circles
    let centerRadius: CGFloat = 100.0 // Central influence radius

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)

                // Circles
                ForEach(circles) { node in
                    NodeView(
                        node: node,
                        position: getPosition(for: node, in: geometry),
                        size: getSize(for: node, in: geometry),
                        isWithinRadius: isWithinRadius(node, in: geometry)
                    ) {
                        selectedNode = node
                        showPopup = true
                    }
                }

                // Popup UI
                VStack {
                    Spacer()
                    if showPopup, let node = selectedNode {
                        HStack {
                            Spacer()
                            VStack {
                                Text(node.letter)
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                    .padding()
                                Button(action: {
                                    showPopup = false
                                }) {
                                    Text("X")
                                        .font(.headline)
                                        .padding()
                                        .frame(width: 40, height: 40)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    }
                }
            }
            .gesture(dragGesture())
            .onAppear {
                setupCircles(in: geometry)
            }
        }
    }

    // Helper Methods
    private func setupCircles(in geometry: GeometryProxy) {
        let width = geometry.size.width
        let height = geometry.size.height

        var generatedCircles: [Node] = []
        while generatedCircles.count < circleCount {
            let position = CGPoint(
                x: CGFloat.random(in: width * 0.1..<width * 0.9),
                y: CGFloat.random(in: height * 0.1..<height * 0.9)
            )
            // Check for overlap
            if !generatedCircles.contains(where: { distance($0.position, position) < 50 }) {
                generatedCircles.append(Node(position: position, letter: randomLetter()))
            }
        }

        circles = generatedCircles
    }

    private func getPosition(for node: Node, in geometry: GeometryProxy) -> CGPoint {
        CGPoint(
            x: node.position.x + offset.width + gestureOffset.width,
            y: node.position.y + offset.height + gestureOffset.height
        )
    }

    private func getSize(for node: Node, in geometry: GeometryProxy) -> CGFloat {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let position = getPosition(for: node, in: geometry)
        let dist = distance(position, center)
        return dist <= centerRadius ? 60 : 30 // Resize multiple circles dynamically
    }

    private func isWithinRadius(_ node: Node, in geometry: GeometryProxy) -> Bool {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let position = getPosition(for: node, in: geometry)
        return distance(position, center) <= centerRadius
    }

    private func randomLetter() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String(letters.randomElement()!)
    }

    private func distance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        hypot(point1.x - point2.x, point1.y - point2.y)
    }

    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                gestureOffset = gesture.translation // Track the temporary offset
            }
            .onEnded { gesture in
                offset.width += gesture.translation.width
                offset.height += gesture.translation.height
                gestureOffset = .zero // Reset the temporary offset
            }
    }
}

// NodeView Component
struct NodeView: View {
    let node: Node
    let position: CGPoint
    let size: CGFloat
    let isWithinRadius: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .background(Circle().fill(Color.blue))
                .frame(width: size, height: size)
                .position(position)
                .onTapGesture {
                    if isWithinRadius {
                        onTap()
                    }
                }

            Text(node.letter)
                .foregroundColor(.white)
                .font(.system(size: size * 0.4, weight: .bold)) // Dynamically scale the text
                .position(position) // Ensure letter moves with circle
        }
        .animation(.easeInOut(duration: 0.5), value: size)
        .animation(.easeInOut(duration: 0.5), value: position)
    }
}

// Node Model
struct Node: Identifiable {
    let id = UUID()
    let position: CGPoint
    let letter: String
}






struct InteractiveWire: Shape {
    var from: CGPoint
    var to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)

        // Simulate a more dynamic floppy curve
        let midPoint = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
        let sag = abs(from.x - to.x) / 2 + 50
        let control1 = CGPoint(x: from.x, y: midPoint.y + sag)
        let control2 = CGPoint(x: to.x, y: midPoint.y - sag)
        path.addCurve(to: to, control1: control1, control2: control2)

        return path
    }
}

struct WireGrabberView_Previews: PreviewProvider {
    static var previews: some View {
        WireGrabberView()
    }
}


struct ContentView: View {
    var body: some View {
        WireGrabberView()
    }
}

#Preview {
    ContentView()
}
