import SwiftUI

struct BlockCardView: View {
    let block: Block
    let onEdit: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(block.type.displayName)
                            .font(.headline)
                        Text(block.displayDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button("Edit", action: onEdit)
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}
