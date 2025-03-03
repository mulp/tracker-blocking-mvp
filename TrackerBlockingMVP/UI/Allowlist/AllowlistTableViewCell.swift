//
//  AllowlistTableViewCell.swift
//  TrackerBlockingMVP
//
//  Created by FC on 28/2/25.
//

import UIKit
import Foundation

class AllowlistTableViewCell: UITableViewCell {
    private let domainLabel: UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        return label
    }()
    
    private let blockLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("allowlist.block.title", comment: "")
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 12)
        label.isHidden = true
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(domainLabel)
        contentView.addSubview(blockLabel)
        
        domainLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        blockLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with domain: String, isSelected: Bool) {
        domainLabel.text = domain
        blockLabel.isHidden = !isSelected
        
        // Visual indication of selection
        contentView.backgroundColor = isSelected
            ? UIColor.systemBlue.withAlphaComponent(0.1)
            : .white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Update cell appearance when selected
        blockLabel.isHidden = !selected
        contentView.backgroundColor = selected
            ? UIColor.systemBlue.withAlphaComponent(0.1)
            : .white
    }
}
