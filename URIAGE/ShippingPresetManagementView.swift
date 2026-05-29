import SwiftUI
import SwiftData

struct ShippingPresetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShippingPreset.createdAt) private var presets: [ShippingPreset]
    @State private var isShowingAddSheet = false

    var body: some View {
        List {
            if presets.isEmpty {
                Section {
                    Text("よく使うサイズが登録されていません。")
                        .foregroundStyle(.secondary)
                    
                    Button("デフォルトを復元") {
                        seedDefaultPresets(modelContext: modelContext)
                    }
                }
            } else {
                ForEach(presets) { preset in
                    NavigationLink {
                        ShippingPresetFormView(preset: preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.title)
                                .font(.headline)
                            Text(preset.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deletePresets)
            }
        }
        .navigationTitle("サイズプリセット管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            NavigationStack {
                ShippingPresetFormView()
            }
        }
    }

    private func deletePresets(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(presets[index])
        }
    }
}

struct ShippingPresetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let preset: ShippingPreset?
    
    @State private var title: String
    @State private var length: String
    @State private var width: String
    @State private var height: String
    @State private var weight: String

    init(preset: ShippingPreset? = nil) {
        self.preset = preset
        _title = State(initialValue: preset?.title ?? "")
        _length = State(initialValue: preset?.length.displayText ?? "")
        _width = State(initialValue: preset?.width.displayText ?? "")
        _height = State(initialValue: preset?.height.displayText ?? "")
        _weight = State(initialValue: preset?.weight.displayText ?? "")
    }

    var body: some View {
        Form {
            Section("プリセット名") {
                TextField("例：ネコポス、60サイズなど", text: $title)
            }
            
            Section("サイズと重量") {
                HStack {
                    Text("長さ")
                    TextField("0", text: $length)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("幅")
                    TextField("0", text: $width)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("高さ")
                    TextField("0", text: $height)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("重量")
                    TextField("0", text: $weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(preset == nil ? "プリセット追加" : "プリセット編集")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(title.isEmpty)
            }
        }
    }

    private func save() {
        let l = Decimal(string: length) ?? 0
        let w = Decimal(string: width) ?? 0
        let h = Decimal(string: height) ?? 0
        let wg = Decimal(string: weight) ?? 0
        
        if let preset = preset {
            preset.title = title
            preset.length = l
            preset.width = w
            preset.height = h
            preset.weight = wg
        } else {
            let newPreset = ShippingPreset(title: title, length: l, width: w, height: h, weight: wg)
            modelContext.insert(newPreset)
        }
        
        dismiss()
    }
}

func seedDefaultPresets(modelContext: ModelContext) {
    let defaults = [
        ShippingPreset(title: "A4・薄手", length: 30, width: 21, height: 2, weight: 150),
        ShippingPreset(title: "A5・薄手", length: 21, width: 15, height: 2, weight: 80),
        ShippingPreset(title: "60サイズ", length: 30, width: 20, height: 10, weight: 1500),
        ShippingPreset(title: "80サイズ", length: 40, width: 25, height: 15, weight: 3000)
    ]
    
    for preset in defaults {
        modelContext.insert(preset)
    }
}

private extension Decimal {
    var displayText: String {
        let number = NSDecimalNumber(decimal: self)
        return number.stringValue
    }
}
