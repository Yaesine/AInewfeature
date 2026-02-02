import SwiftUI

struct BlockCardView: View {
    let block: Block
    let onEdit: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    IconBadge(systemName: block.type == .ai ? "sparkles" : "wand.and.stars")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(block.type.displayName)
                            .font(.headline)
                        Text(block.displayDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Menu {
                        Button("Edit") { onEdit() }
                        if let onMoveUp {
                            Button("Move Up") { onMoveUp() }
                        }
                        if let onMoveDown {
                            Button("Move Down") { onMoveDown() }
                        }
                        if let onDelete {
                            Divider()
                            Button("Delete", role: .destructive) { onDelete() }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}
