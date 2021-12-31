//
//  LiveRoomVC+Bottom.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/29.
//

import Foundation

extension LiveRoomVC : LiveBottomViewDelegate {
    
    func liveBottomView(_ bottomView: LiveBottomView, didClickButtonWith action: LiveBottomAction) {
        print("liveBottomView did click button: \(action)")
        switch action {
        case .message:
            print("liveBottomView did click button: \(action)")
        case .share:
            print("liveBottomView did click button: \(action)")
        case .beauty:
            self.faceBeautifyView?.isHidden = !(self.faceBeautifyView?.isHidden ?? false)
        case .soundEffect:
                print("liveBottomView did click button: \(action)")
        case .more:
                print("liveBottomView did click button: \(action)")
        case .apply:
                print("liveBottomView did click button: \(action)")
        case .flip:
                print("liveBottomView did click button: \(action)")
        case .camera:
                print("liveBottomView did click button: \(action)")
        case .mic:
                print("liveBottomView did click button: \(action)")
        case .end:
                print("liveBottomView did click button: \(action)")
        }
    }
}