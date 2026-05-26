import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var viewModel: ClipboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button("Clear All") {
                    viewModel.clearAll()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            TextField("Search...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .focusable(false)

            Divider()

            if viewModel.filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No clipboard history")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: index == viewModel.selectedIndex,
                                    onSelect: { viewModel.selectItem(item) },
                                    onDelete: { viewModel.deleteItem(item) }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: viewModel.selectedIndex) { newIndex in
                        let items = viewModel.filteredItems
                        if newIndex >= 0 && newIndex < items.count {
                            withAnimation {
                                proxy.scrollTo(items[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 320, height: 420)
        .background(VisualEffectView())
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
