import WidgetKit
import SwiftUI

@main
struct YolklingWidgetBundle: WidgetBundle {
    var body: some Widget {
        YolkRoomWidget()
        FocusLiveActivity()
    }
}
