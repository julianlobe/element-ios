// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import SwiftUI
import Combine

final class RoomNotificationSettingsViewModel: RoomNotificationSettingsViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomNotificationService: RoomNotificationSettingsServiceType
    private let avatarService: AvatarServiceType
    private var state: RoomNotificationSettingsViewState {
        willSet {
            update(viewState: newValue)
        }
    }
    @available(iOS 14.0, *)
    @Published var viewState: RoomNotificationSettingsViewState!
    @available(iOS 14.0, *)
    lazy var cancellables = Set<AnyCancellable>()
    
    // MARK: Public
    
    weak var viewDelegate: RoomNotificationSettingsViewModelViewDelegate?
    
    weak var coordinatorDelegate: RoomNotificationSettingsViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(
        roomNotificationService: RoomNotificationSettingsServiceType,
        avatarService: AvatarServiceType,
        avatarData: AvatarInputOption?,
        roomEncrypted: Bool
    ) {
        self.roomNotificationService = roomNotificationService
        self.avatarService = avatarService
        
        let notificationState = Self.mapNotificationStateOnRead(encrypted: roomEncrypted, state: roomNotificationService.notificationState)
        let initialState = RoomNotificationSettingsViewState(roomEncrypted: roomEncrypted, saving: false, notificationState: notificationState, avatar: nil)
        self.state = initialState
        
        if #available(iOS 14.0, *) {
            self.viewState = initialState
        }
        
        self.roomNotificationService.observeNotificationState { [weak self] state in
            guard let self = self else { return }
            self.state.notificationState = Self.mapNotificationStateOnRead(encrypted: roomEncrypted, state: state)
        }
        
        if #available(iOS 14.0, *),
           let avatarData = avatarData,
           case let AvatarInputOption.swiftUI(data) = avatarData {
            avatarService.avatarImage(inputData: data)
                .sink { image in
                    var newState = self.state
                    newState.avatar = image
                    newState.displayName = data.displayName
                    self.state = newState
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Public 
    
    func process(viewAction: RoomNotificationSettingsViewAction) {
        switch viewAction {
        case .load:
            update(viewState: self.state)
        case .selectNotificationState(let state):
            self.state.notificationState = state
        case .save:
            self.state.saving = true
            roomNotificationService.update(state: state.notificationState) { [weak self] in
                guard let self = self else { return }
                self.state.saving = false
                self.coordinatorDelegate?.roomNotificationSettingsViewModelDidComplete(self)
            }
        case .cancel:
            coordinatorDelegate?.roomNotificationSettingsViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private static func mapNotificationStateOnRead(encrypted: Bool, state: RoomNotificationState) -> RoomNotificationState {
        if encrypted, case .mentionsAndKeywordsOnly = state {
            // Notifications not supported on encrypted rooms, map mentionsOnly to mute on read
            return .mute
        } else {
            return state
        }
    }
    
    private func update(viewState: RoomNotificationSettingsViewState) {
        self.viewDelegate?.roomNotificationSettingsViewModel(self, didUpdateViewState: viewState)
        
        if #available(iOS 14.0, *) {
            self.viewState = viewState
        }
    }
}

@available(iOS 14.0, *)
extension RoomNotificationSettingsViewModel: ObservableObject {}
