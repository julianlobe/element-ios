// File created from SimpleUserProfileExample
// $ createScreen.sh Room/PollEditForm PollEditForm
// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

@available(iOS 14.0, *)
struct PollTimeline: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: PollTimelineViewModel.Context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            
            Text(viewModel.viewState.poll.question)
                .font(theme.fonts.bodySB)
            
            VStack(spacing: 24.0) {
                ForEach(viewModel.viewState.poll.answerOptions) { answerOption in
                    Button {
                        viewModel.send(viewAction: .selectAnswerOptionWithIdentifier(answerOption.id))
                    } label: {
                        let rect = RoundedRectangle(cornerRadius: 4.0)
                        VStack(alignment: .leading, spacing: 12.0) {
                            HStack(alignment: .top, spacing: 8.0) {
                                
                                if !viewModel.viewState.poll.closed {
                                    Image(uiImage: answerOption.selected ? Asset.Images.pollCheckboxSelected.image : Asset.Images.pollCheckboxDefault.image)
                                }
                                
                                Text(answerOption.text)
                                    .font(theme.fonts.body)
                                    .foregroundColor(theme.colors.primaryContent)
                            }
                            
                            HStack {
                                ProgressView(value: Double(answerOption.count),
                                             total: Double(viewModel.viewState.poll.totalAnswerCount))
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .scaleEffect(x: 1.0, y: 1.2, anchor: .center)
                                    .padding([.top, .bottom], 8.0)
                                
                                if viewModel.viewState.poll.closed && answerOption.winner {
                                    Image(uiImage: Asset.Images.pollWinnerIcon.image)
                                }
                                
                                if (viewModel.viewState.poll.totalAnswerCount > 0) {
                                    Text((answerOption.count == 1 ?
                                            VectorL10n.pollTimelineOneVote :
                                            VectorL10n.pollTimelineVotesCount(Int(answerOption.count))))
                                        .font(theme.fonts.footnote)
                                        .foregroundColor(viewModel.viewState.poll.closed && answerOption.winner ? theme.colors.accent : theme.colors.secondaryContent)
                                }
                            }
                        }
                        .padding([.leading, .trailing], 8.0)
                        .padding(.top, 12.0)
                        .padding(.bottom, 4.0)
                        .clipShape(rect)
                        .overlay(rect.stroke(accentColorForAnswerOption(answerOption) , lineWidth: 1.0))
                        .accentColor(accentColorForAnswerOption(answerOption))
                    }
                }
            }
            .disabled(viewModel.viewState.poll.closed)
            .fixedSize(horizontal: false, vertical: true)
            .alert(isPresented: $viewModel.showsAnsweringFailureAlert) {
                Alert(title: Text(VectorL10n.pollTimelineNotClosedTitle),
                      message: Text(VectorL10n.pollTimelineNotClosedSubtitle),
                      dismissButton: .default(Text(VectorL10n.pollTimelineNotClosedAction)))
            }
            .alert(isPresented: $viewModel.showsClosingFailureAlert) {
                Alert(title: Text(VectorL10n.pollTimelineVoteNotRegisteredTitle),
                      message: Text(VectorL10n.pollTimelineVoteNotRegisteredSubtitle),
                      dismissButton: .default(Text(VectorL10n.pollTimelineVoteNotRegisteredAction)))
            }
            
            if (viewModel.viewState.poll.totalAnswerCount > 0) {
                Text(viewModel.viewState.poll.totalAnswerCount == 1 ?
                        VectorL10n.pollTimelineTotalOneVote :
                        VectorL10n.pollTimelineTotalVotesCount(Int(viewModel.viewState.poll.totalAnswerCount)))
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.tertiaryContent)
            }
        }
        .padding([.leading, .trailing, .top], 2.0)
        .padding([.bottom])
    }
    
    private func accentColorForAnswerOption(_ answerOption: TimelineAnswerOption) -> Color {
        guard !viewModel.viewState.poll.closed else {
            return theme.colors.quarterlyContent
        }
        
        return (answerOption.selected ? theme.colors.accent : theme.colors.quarterlyContent)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct PollTimeline_Previews: PreviewProvider {
    static let stateRenderer = MockPollTimelineScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
