import SwiftUI

/// Wallhaven-specific settings view
struct WallhavenSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var preferences = Preferences.shared
  
  var body: some View {
    Form {
      Section("Search") {
        TextField("Search query (e.g., nature,landscape)", text: $preferences.wallhavenSearchQuery)
        
        Picker("Sorting", selection: $preferences.wallhavenSorting) {
                Text("Random").tag("random")
                Text("Date Added").tag("date_added")
                Text("Relevance").tag("relevance")
                Text("Views").tag("views")
                Text("Favorites").tag("favorites")
                Text("Toplist").tag("toplist")
            }

            if preferences.wallhavenSorting == "toplist" || preferences.wallhavenSorting == "favorites" {
                Picker("Time Range", selection: $preferences.wallhavenTopRange) {
                    Text("Last Day").tag("1d")
                    Text("Last 3 Days").tag("3d")
                    Text("Last Week").tag("1w")
                    Text("Last Month").tag("1M")
                    Text("Last 3 Months").tag("3M")
                    Text("Last 6 Months").tag("6M")
                    Text("Last Year").tag("1y")
                }
            }
      }
      
      Section("Categories") {
        Toggle("General", isOn: categoryBinding(for: 0))
        Toggle("Anime", isOn: categoryBinding(for: 1))
        Toggle("People", isOn: categoryBinding(for: 2))
      }
      
      Section("Purity") {
        Picker("Purity", selection: $preferences.wallhavenPurity) {
          Text("SFW").tag("100")
          Text("Sketchy").tag("110")
          Text("NSFW").tag("111")
        }
      }
      
      Section("Resolution") {
        TextField("Min resolution (e.g., 1920x1080)", text: $preferences.wallhavenResolution)
        
        Picker("Aspect Ratio", selection: $preferences.wallhavenRatio) {
          Text("Any").tag("")
          Text("16:9").tag("16x9")
          Text("16:10").tag("16x10")
          Text("4:3").tag("4x3")
          Text("21:9").tag("21x9")
        }
      }
      
      Section {
        Button("Reset to Defaults") {
          resetToDefaults()
        }
      }
    }
    .formStyle(.grouped)
    .frame(width: 450, height: 500)
    .navigationTitle("Wallhaven Settings")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Done") {
          dismiss()
        }
      }
    }
  }
  
  func categoryBinding(for index: Int) -> Binding<Bool> {
    Binding(
      get: {
        let categories = preferences.wallhavenCategories
        if let idx = categories.utf16.index(categories.startIndex, offsetBy: index, limitedBy: categories.endIndex) {
          return String(categories[idx]) == "1"
        }
        return false
      },
      set: { newValue in
        var categories = preferences.wallhavenCategories
        while categories.count <= index {
          categories += "0"
        }
        if let idx = categories.utf16.index(categories.startIndex, offsetBy: index, limitedBy: categories.endIndex) {
          categories = String(categories.replacingCharacters(in: idx...idx, with: newValue ? "1" : "0"))
          preferences.wallhavenCategories = categories
        }
      }
    )
  }
  
  func resetToDefaults() {
    preferences.wallhavenSearchQuery = ""
    preferences.wallhavenCategories = "111"
    preferences.wallhavenPurity = "100"
    preferences.wallhavenSorting = "random"
    preferences.wallhavenResolution = ""
    preferences.wallhavenRatio = ""
  }
}

struct WallhavenSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    WallhavenSettingsView()
  }
}
