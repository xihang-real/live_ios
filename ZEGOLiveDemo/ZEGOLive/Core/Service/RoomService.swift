//
//  ZegoRoomService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZIM

protocol RoomServiceDelegate: AnyObject {
    func receiveRoomInfoUpdate(_ info: RoomInfo?)
}

class RoomService: NSObject {
    
    // MARK: - Private
    override init() {
        super.init()
        
        // RoomManager didn't finish init at this time.
        DispatchQueue.main.async {
            RoomManager.shared.addZIMEventHandler(self)
        }
    }
    
    // MARK: - Public
    
    var roomInfo: RoomInfo = RoomInfo()
    weak var delegate: RoomServiceDelegate?
    var operation: OperationCommand = OperationCommand()
    /// Create a chat room
    /// You need to enter a generated `rtc token`
    func createRoom(_ roomID: String, _ roomName: String, _ token: String, callback: RoomCallback?) {
        guard roomID.count != 0 else {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        let parameters = getCreateRoomParameters(roomID, roomName)
        ZIMManager.shared.zim?.createRoom(parameters.0, config: parameters.1, callback: { fullRoomInfo, error in
            
            var result: ZegoResult = .success(())
            if error.code == .ZIMErrorCodeSuccess {
                RoomManager.shared.roomService.roomInfo = parameters.2
                RoomManager.shared.userService.localUserInfo?.role = .host
                RoomManager.shared.loginRtcRoom(with: token)
            }
            else {
                if error.code == .ZIMErrorCodeCreateExistRoom {
                    result = .failure(.roomExisted)
                } else {
                    result = .failure(.other(Int32(error.code.rawValue)))
                }
            }
            
            guard let callback = callback else { return }
            callback(result)
        })
        
    }
    
    /// Join a chat room
    /// You need to enter a generated `rtc token`
    func joinRoom(_ roomID: String, _ token: String, callback: RoomCallback?) {
        ZIMManager.shared.zim?.joinRoom(roomID, callback: { fullRoomInfo, error in
            if error.code != .ZIMErrorCodeSuccess {
                guard let callback = callback else { return }
                if error.code == .ZIMErrorCodeRoomNotExist {
                    callback(.failure(.roomNotFound))
                } else {
                    callback(.failure(.other(Int32(error.code.rawValue))))
                }
                return
            }
            
            RoomManager.shared.roomService.roomInfo.roomID = fullRoomInfo.baseInfo.roomID
            RoomManager.shared.roomService.roomInfo.roomName = fullRoomInfo.baseInfo.roomName
            RoomManager.shared.loginRtcRoom(with: token)
            
            guard let callback = callback else { return }
            callback(.success(()))
        })
    }
    
    /// Leave the chat room
    func leaveRoom(callback: RoomCallback?) {
        // if call the leave room api, just logout rtc room
        RoomManager.shared.logoutRtcRoom()
        
        guard let roomID = RoomManager.shared.roomService.roomInfo.roomID else {
            assert(false, "room ID can't be nil")
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        ZIMManager.shared.zim?.leaveRoom(roomID, callback: { error in
            var result: ZegoResult = .success(())
            if error.code != .ZIMErrorCodeSuccess {
                result = .failure(.other(Int32(error.code.rawValue)))
            }
            guard let callback = callback else { return }
            callback(result)
        })
    }
}

// MARK: - Private
extension RoomService {
    
    private func getCreateRoomParameters(_ roomID: String, _ roomName: String) -> (ZIMRoomInfo, ZIMRoomAdvancedConfig, RoomInfo) {
        
        let zimRoomInfo = ZIMRoomInfo()
        zimRoomInfo.roomID = roomID
        zimRoomInfo.roomName = roomName
        
        let roomInfo = RoomInfo()
        roomInfo.hostID = RoomManager.shared.userService.localUserInfo?.userID
        roomInfo.roomID = roomID
        roomInfo.roomName = roomName.count > 0 ? roomName : roomID
        
        let config = ZIMRoomAdvancedConfig()
        let roomInfoJson = ZegoJsonTool.modelToJson(toString: roomInfo) ?? ""
        
        config.roomAttributes = ["roomInfo" : roomInfoJson]
        
        return (zimRoomInfo, config, roomInfo)
    }
}

extension RoomService: ZIMEventHandler {
    
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        // if host reconneted
        if state == .connected && event == .success {
            guard let roomID = RoomManager.shared.roomService.roomInfo.roomID else { return }
            ZIMManager.shared.zim?.queryRoomAllAttributes(byRoomID: roomID, callback: { dict, error in
                if error.code != .ZIMErrorCodeSuccess { return }
                if dict.count == 0 {
                    self.delegate?.receiveRoomInfoUpdate(nil)
                }
            })
        }
    }
    
    func zim(_ zim: ZIM, roomAttributesUpdated updateInfo: ZIMRoomAttributesUpdateInfo, roomID: String) {
        
        // update room info
        if updateInfo.roomAttributes.keys.contains("roomInfo") {
            let roomJson = updateInfo.roomAttributes["roomInfo"] ?? ""
            let roomInfo = ZegoJsonTool.jsonToModel(type: RoomInfo.self, json: roomJson)
            
            // if the room info is nil, we should not set self.info = nil
            // because it can't get room info outside.
            if let roomInfo = roomInfo {
                self.roomInfo = roomInfo
            }
            delegate?.receiveRoomInfoUpdate(roomInfo)
        }
        
        // update action
        guard let actionJson = updateInfo.roomAttributes["action"],
              let action: OperationAction = ZegoJsonTool.jsonToModel(type: OperationAction.self, json: actionJson)
        else {
            return
        }
        
        roomAttributesUpdated(updateInfo.roomAttributes, action: action)
    }
}
