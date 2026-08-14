//
//  FreelanceSchedulerWidgetExtensionBundle.swift
//  FreelanceSchedulerWidgetExtension
//
//  Created by 진태영 on 8/14/26.
//

import WidgetKit
import SwiftUI

@main
struct FreelanceSchedulerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        FreelanceSchedulerWidgetExtension()
        FreelanceSchedulerWidgetExtensionControl()
    }
}
