//
//  SettingSwitchCell.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/5.
//

import UIKit

protocol SettingSwitchCellDelegate {
    func cellSwitchValueChange(_ value: Bool)
}

class SettingSwitchCell: SettingBaseCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchButton: UISwitch!
    
    var delegate: SettingSwitchCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func updateCell(_ model: LiveSettingModel) {
        super.updateCell(model)
        cellModel = model
        titleLabel.text = model.title
        switchButton.isOn = model.switchStatus
    }
    
    @IBAction func switchValueChange(_ sender: UISwitch) {
        delegate?.cellSwitchValueChange(sender.isOn)
    }
}