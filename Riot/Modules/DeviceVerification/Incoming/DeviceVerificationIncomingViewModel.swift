// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2019 New Vector Ltd
 
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

final class DeviceVerificationIncomingViewModel: DeviceVerificationIncomingViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXIncomingSASTransaction
    
    // MARK: Public

    var userId: String
    var userDisplayName: String?
    var avatarUrl: String?
    var deviceId: String

    var mediaManager: MXMediaManager

    weak var viewDelegate: DeviceVerificationIncomingViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationIncomingViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, transaction: MXIncomingSASTransaction) {
        self.session = session
        self.transaction = transaction
        self.userId = otherUser.userId
        self.userDisplayName = otherUser.displayname
        self.avatarUrl = otherUser.avatarUrl
        self.deviceId = transaction.otherDeviceId

        self.mediaManager = session.mediaManager

        self.registerTransactionDidStateChangeNotification(transaction: transaction)
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationIncomingViewAction) {
        switch viewAction {
        case .accept:
            self.acceptIncomingDeviceVerification()
        case .cancel:
            self.rejectIncomingDeviceVerification()
            self.coordinatorDelegate?.deviceVerificationIncomingViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func acceptIncomingDeviceVerification() {
        self.update(viewState: .loading)
        self.transaction.accept()
    }

    private func rejectIncomingDeviceVerification() {
        self.transaction.cancel(with: MXTransactionCancelCode.user())
    }
    
    private func update(viewState: DeviceVerificationIncomingViewState) {
        self.viewDelegate?.deviceVerificationIncomingViewModel(self, didUpdateViewState: viewState)
    }

    // MARK: - MXDeviceVerificationTransactionDidChange

    private func registerTransactionDidStateChangeNotification(transaction: MXIncomingSASTransaction) {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: NSNotification.Name.MXDeviceVerificationTransactionDidChange, object: transaction)
    }

    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXIncomingSASTransaction else {
            return
        }

        switch transaction.state {
        case MXSASTransactionStateShowSAS:
            self.update(viewState: .loaded)
            self.coordinatorDelegate?.deviceVerificationIncomingViewModel(self, didAcceptTransaction: self.transaction)
        case MXSASTransactionStateCancelled:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            self.update(viewState: .cancelled(reason))
        case MXSASTransactionStateCancelledByMe:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            self.update(viewState: .cancelledByMe(reason))
        default:
            break
        }
    }
}
