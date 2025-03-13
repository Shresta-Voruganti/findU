import SwiftUI

struct TextStyle {
    var font: Font = .system(.body)
    var color: Color = .primary
    var alignment: TextAlignment = .leading
    var lineSpacing: CGFloat = 1
    var tracking: CGFloat = 0
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderlined: Bool = false
}

struct TextEditorView: View {
    @Binding var text: String
    @Binding var style: TextStyle
    let fonts: [Font]
    let onTextChange: ((String) -> Void)?
    
    @State private var selectedTab = 0
    @State private var showingColorPicker = false
    
    init(text: Binding<String>,
         style: Binding<TextStyle>,
         fonts: [Font] = [
            .system(.largeTitle),
            .system(.title),
            .system(.title2),
            .system(.title3),
            .system(.headline),
            .system(.subheadline),
            .system(.body),
            .system(.callout),
            .system(.caption),
            .system(.caption2)
         ],
         onTextChange: ((String) -> Void)? = nil) {
        self._text = text
        self._style = style
        self.fonts = fonts
        self.onTextChange = onTextChange
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Text Preview
            ScrollView {
                Text(text)
                    .font(style.font)
                    .foregroundColor(style.color)
                    .multilineTextAlignment(style.alignment)
                    .lineSpacing(style.lineSpacing)
                    .tracking(style.tracking)
                    .bold(style.isBold)
                    .italic(style.isItalic)
                    .underline(style.isUnderlined)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 150)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Text Input
            TextField("Enter text", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onChange(of: text) { newValue in
                    onTextChange?(newValue)
                }
            
            // Style Options
            Picker("Style Options", selection: $selectedTab) {
                Text("Font").tag(0)
                Text("Style").tag(1)
                Text("Layout").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            TabView(selection: $selectedTab) {
                // Font Options
                fontOptionsView
                    .tag(0)
                
                // Style Options
                styleOptionsView
                    .tag(1)
                
                // Layout Options
                layoutOptionsView
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
        }
        .sheet(isPresented: $showingColorPicker) {
            NavigationView {
                ColorPickerView(selectedColor: $style.color)
                    .navigationTitle("Text Color")
                    .navigationBarItems(trailing: Button("Done") {
                        showingColorPicker = false
                    })
            }
        }
    }
    
    private var fontOptionsView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(fonts, id: \.self) { font in
                    Button {
                        style.font = font
                    } label: {
                        Text("Sample Text")
                            .font(font)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(style.font == font ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    private var styleOptionsView: some View {
        VStack(spacing: 16) {
            // Color Button
            Button {
                showingColorPicker = true
            } label: {
                HStack {
                    Text("Color")
                    Spacer()
                    Circle()
                        .fill(style.color)
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Style Toggles
            HStack(spacing: 20) {
                Toggle("Bold", isOn: $style.isBold)
                Toggle("Italic", isOn: $style.isItalic)
                Toggle("Underline", isOn: $style.isUnderlined)
            }
            .toggleStyle(.button)
            
            // Tracking
            VStack(alignment: .leading) {
                Text("Letter Spacing")
                Slider(value: $style.tracking, in: -5...10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var layoutOptionsView: some View {
        VStack(spacing: 16) {
            // Alignment
            Picker("Alignment", selection: $style.alignment) {
                Image(systemName: "text.alignleft")
                    .tag(TextAlignment.leading)
                Image(systemName: "text.aligncenter")
                    .tag(TextAlignment.center)
                Image(systemName: "text.alignright")
                    .tag(TextAlignment.trailing)
            }
            .pickerStyle(.segmented)
            
            // Line Spacing
            VStack(alignment: .leading) {
                Text("Line Spacing")
                Slider(value: $style.lineSpacing, in: 0...10)
            }
        }
        .padding()
    }
}

struct TextEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(
            text: .constant("Sample Text"),
            style: .constant(TextStyle())
        )
    }
} 