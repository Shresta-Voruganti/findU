import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    let presetColors: [Color]
    let onColorSelected: ((Color) -> Void)?
    
    @State private var customColor: Color = .white
    @State private var showingCustomPicker = false
    @State private var selectedTab = 0
    
    init(selectedColor: Binding<Color>,
         presetColors: [Color] = [
            .white, .black, .gray,
            .red, .orange, .yellow,
            .green, .blue, .purple,
            .pink, .brown, .mint,
            .teal, .cyan, .indigo
         ],
         onColorSelected: ((Color) -> Void)? = nil) {
        self._selectedColor = selectedColor
        self.presetColors = presetColors
        self.onColorSelected = onColorSelected
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Color Preview
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedColor)
                .frame(height: 100)
                .shadow(radius: 2)
                .padding(.horizontal)
            
            // Color Selection Tabs
            Picker("Color Selection", selection: $selectedTab) {
                Text("Presets").tag(0)
                Text("Custom").tag(1)
                Text("Gradient").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            TabView(selection: $selectedTab) {
                // Preset Colors
                presetColorsView
                    .tag(0)
                
                // Custom Color
                customColorView
                    .tag(1)
                
                // Gradient Colors
                gradientColorsView
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Apply Button
            if let onColorSelected = onColorSelected {
                Button {
                    onColorSelected(selectedColor)
                } label: {
                    Text("Apply Color")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    private var presetColorsView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60))
            ], spacing: 12) {
                ForEach(presetColors, id: \.self) { color in
                    ColorButton(
                        color: color,
                        isSelected: color == selectedColor
                    ) {
                        selectedColor = color
                    }
                }
            }
            .padding()
        }
    }
    
    private var customColorView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Red")
                Slider(value: Binding(
                    get: { UIColor(customColor).redComponent },
                    set: { updateCustomColor(red: $0) }
                ), in: 0...1)
            }
            
            HStack {
                Text("Green")
                Slider(value: Binding(
                    get: { UIColor(customColor).greenComponent },
                    set: { updateCustomColor(green: $0) }
                ), in: 0...1)
            }
            
            HStack {
                Text("Blue")
                Slider(value: Binding(
                    get: { UIColor(customColor).blueComponent },
                    set: { updateCustomColor(blue: $0) }
                ), in: 0...1)
            }
            
            HStack {
                Text("Alpha")
                Slider(value: Binding(
                    get: { UIColor(customColor).alphaComponent },
                    set: { updateCustomColor(alpha: $0) }
                ), in: 0...1)
            }
            
            Button("Apply Custom Color") {
                selectedColor = customColor
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var gradientColorsView: some View {
        VStack(spacing: 16) {
            ForEach([
                GradientPreset(colors: [.blue, .purple], name: "Ocean"),
                GradientPreset(colors: [.orange, .red], name: "Sunset"),
                GradientPreset(colors: [.green, .yellow], name: "Spring"),
                GradientPreset(colors: [.purple, .pink], name: "Berry"),
                GradientPreset(colors: [.blue, .green], name: "Forest"),
            ], id: \.name) { gradient in
                Button {
                    selectedColor = gradient.colors[0]
                } label: {
                    LinearGradient(
                        colors: gradient.colors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 44)
                    .cornerRadius(8)
                    .overlay(
                        Text(gradient.name)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    )
                }
            }
        }
        .padding()
    }
    
    private func updateCustomColor(
        red: CGFloat? = nil,
        green: CGFloat? = nil,
        blue: CGFloat? = nil,
        alpha: CGFloat? = nil
    ) {
        let uiColor = UIColor(customColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let newColor = UIColor(
            red: red ?? r,
            green: green ?? g,
            blue: blue ?? b,
            alpha: alpha ?? a
        )
        customColor = Color(uiColor: newColor)
    }
}

private struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .shadow(radius: 2)
        }
    }
}

private struct GradientPreset {
    let colors: [Color]
    let name: String
}

struct ColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerView(selectedColor: .constant(.blue))
    }
} 