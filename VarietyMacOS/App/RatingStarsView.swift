import SwiftUI

/// Interactive 5-star rating view
@MainActor
struct RatingStarsView: View {
    let rating: Int?  // 1-5, nil = unrated
    let onRatingChange: (Int?) -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { starIndex in
                Image(systemName: starIconName(for: starIndex))
                    .font(.body)
                    .foregroundColor(starIndex <= (rating ?? 0) ? .yellow : .gray)
                    .onTapGesture {
                        toggleRating(for: starIndex)
                    }
            }
        }
    }
    
    private func starIconName(for starIndex: Int) -> String {
        if let rating = rating, starIndex <= rating {
            return "star.fill"  // Filled star for rated
        }
        return "star"  // Outline star
    }
    
    private func toggleRating(for starIndex: Int) {
        if rating == starIndex {
            // Toggle off if clicking same star
            onRatingChange(nil)
        } else {
            onRatingChange(starIndex)
        }
    }
}

#Preview("Rated 3 stars") {
    RatingStarsView(rating: 3) { newRating in
        print("New rating: \(String(describing: newRating))")
    }
}

#Preview("Unrated") {
    RatingStarsView(rating: nil) { newRating in
        print("New rating: \(String(describing: newRating))")
    }
}

#Preview("Rated 5 stars") {
    RatingStarsView(rating: 5) { newRating in
        print("New rating: \(String(describing: newRating))")
    }
}