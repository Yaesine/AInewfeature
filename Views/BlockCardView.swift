import SwiftUI

struct BlockCardView: View {
    let block: Block
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(block.type.displayName)
                    .font(.headline)
                Spacer()
                Button("Edit", action: onEdit)
                    .buttonStyle(.bordered)
            }
            Text(block.displayDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
