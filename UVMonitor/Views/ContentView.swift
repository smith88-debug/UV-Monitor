import SwiftUI

struct ContentView: View {
    var dataManager: UVDataManager

    var body: some View {
        DashboardView(dataManager: dataManager)
    }
}
