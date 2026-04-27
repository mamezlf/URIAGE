//
//  MercariLinkImportView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/27.
//

import SwiftUI
import SwiftData
import UIKit

struct MercariLinkImportView: View {
    var onRecordSaved: (() -> Void)?

    @State private var linkText = ""
    @State private var importedItem: MercariItemImportResult?
    @State private var fallbackItem: MercariItemImportResult?
    @State private var alertMessage: String?
    @State private var isShowingAlert = false
    @State private var isImporting = false

    private var trimmedLink: String {
        linkText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.Metrics.controlCornerRadius, style: .continuous)
                            .fill(AppTheme.Colors.primary.opacity(0.12))

                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .frame(width: 64, height: 64)

                    Text("Mercari商品共有リンクから記録")
                        .font(.title2.bold())

                    ZStack(alignment: .topLeading) {
                        TextField("", text: $linkText, axis: .vertical)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .lineLimit(3...5)
                            .textFieldStyle(.plain)
                            .tint(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .padding(.trailing, linkText.isEmpty ? 0 : 28)

                        if linkText.isEmpty {
                            Text("https://jp.mercari.com/item/…")
                                .foregroundColor(.gray)
                                .tint(.gray)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(.separator).opacity(0.65), lineWidth: 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        if !linkText.isEmpty {
                            Button {
                                linkText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                            .accessibilityLabel("クリア")
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            pasteFromClipboard()
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("貼り付け")
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                Button {
                    Task {
                        await importItem()
                    }
                } label: {
                    HStack {
                        Label("読み込んで記録へ", systemImage: "arrow.right.circle.fill")

                        Spacer()

                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isImporting || trimmedLink.isEmpty)
            }

            Section {
                NavigationLink {
                    SoldItemFormView(onSaveComplete: onRecordSaved)
                } label: {
                    Label("手入力で記録", systemImage: "square.and.pencil")
                }
            }
        }
        .navigationTitle("リンク入力")
        .navigationDestination(item: $importedItem) { item in
            SoldItemFormView(importedMercariItem: item, onSaveComplete: onRecordSaved)
        }
        .alert("リンク読み込み", isPresented: $isShowingAlert) {
            if let fallbackItem {
                Button("手入力に進む") {
                    importedItem = fallbackItem
                    self.fallbackItem = nil
                }
            }

            Button("確認", role: .cancel) {
                fallbackItem = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func pasteFromClipboard() {
        guard let clipboardText = UIPasteboard.general.string else {
            return
        }

        linkText = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func importItem() async {
        isImporting = true
        defer {
            isImporting = false
        }

        do {
            importedItem = try await MercariItemImporter.fetch(from: linkText)
        } catch {
            if let normalized = try? MercariItemImporter.normalize(linkText) {
                fallbackItem = normalized
            } else {
                fallbackItem = nil
            }

            alertMessage = error.localizedDescription
            isShowingAlert = true
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MercariLinkImportView()
    }
    .modelContainer(for: [SoldItem.self, SupplyItem.self], inMemory: true)
}
#endif
