//
//  BrowserView.swift
//  TrackerBlockingMVP
//
//  Created by FC on 25/2/25.
//

import UIKit
import WebKit

public final class BrowserView: UIView {
    // MARK: - UI Components
    private(set) var webView: WKWebView = {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.isUserInteractionEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()
    
    private(set) var urlField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = NSLocalizedString("browser.url.bar.placeholder", comment: "")
        textField.returnKeyType = .go
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    private(set) lazy var privacyActionButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config, primaryAction: nil)
        button.addTarget(self, action: #selector(didTapOnActionButton), for: .touchUpInside)
        button.configuration = config
        return button
    }()
    private let toastView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.alpha = 0
        return view
    }()
    private let toastLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private(set) lazy var testButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "shield.checkerboard")
        config.baseForegroundColor = .systemYellow
        config.baseBackgroundColor = .clear
        let button = UIButton(configuration: config, primaryAction: nil)
        button.addTarget(self, action: #selector(testTrackerBlocking), for: .touchUpInside)
        button.configuration = config
        return button
    }()
    private(set) lazy var backButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left")
        config.baseForegroundColor = .systemBlue
        config.baseBackgroundColor = .clear
        let button = UIButton(configuration: config, primaryAction: nil)
        button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    private(set) lazy var forwardButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.right")
        config.baseForegroundColor = .systemBlue
        config.baseBackgroundColor = .clear
        let button = UIButton(configuration: config, primaryAction: nil)
        button.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    private let navigationContainer = UIView()
    private let buttonsContainerView = UIView()
    private var errorView: UIView?

    var didTapOnPrivacyActionButton: (() -> Void)?
    var didTapOnTestActionButton: (() -> Void)?

    public init() {
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
        urlField.rightView = buttonsContainerView
        urlField.rightViewMode = .always
        backgroundColor = .white
     }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Private methods
    private func setupSubviews() {
        backgroundColor = .white
        [privacyActionButton, testButton].forEach(buttonsContainerView.addSubview(_:))
        [backButton, forwardButton].forEach(navigationContainer.addSubview(_:))
        toastView.addSubview(toastLabel)
        [navigationContainer, urlField, webView, toastView].forEach(addSubview(_:))
    }

    private func setupConstraints() {
        navigationContainer.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(8)
            $0.height.equalTo(40)
            $0.width.equalTo(60)
        }

        backButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.size.equalTo(CGSize(width: 20, height: 40))
        }
        
        forwardButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(backButton.snp.trailing).offset(5)
            $0.size.equalTo(CGSize(width: 20, height: 40))
        }

        urlField.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalTo(navigationContainer.snp.trailing)
            $0.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(40)
        }
        
        webView.snp.makeConstraints {
            $0.top.equalTo(urlField.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        toastView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-50)
            $0.width.lessThanOrEqualToSuperview().offset(-40)
            $0.height.greaterThanOrEqualTo(40)
        }
        
        toastLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15))
        }
        
        privacyActionButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.leading.equalTo(testButton.snp.trailing).inset(2)
        }

        testButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview()
        }
    }
    
    @objc private func didTapOnActionButton() {
        didTapOnPrivacyActionButton?()
    }
    
    @objc private func testTrackerBlocking() {
        didTapOnTestActionButton?()
    }
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    private func updatePrivacyActionButton(isEnabled: Bool) {
        var config = UIButton.Configuration.plain()
        if isEnabled {
            // Protection enabled - show shield is active
            config.image = UIImage(systemName: "shield.fill")
            config.baseForegroundColor = .systemGreen
        } else {
            // Protection disabled - show shield is inactive
            config.image = UIImage(systemName: "shield.slash")
            config.baseForegroundColor = .systemRed
        }
        config.baseBackgroundColor = .clear
        privacyActionButton.configuration = config
    }
    
    // MARK: Public
    public func setPrivacyButtonState(enable: Bool) {
        privacyActionButton.isSelected = enable
        updatePrivacyActionButton(isEnabled: enable)
    }
    
    public func hideToast() {
        UIView.animate(withDuration: 0.3, animations: {
            self.toastView.alpha = 0
        })
    }

    public func showToast(message: String) {
        hideToast()
        toastLabel.text = message
        UIView.animate(withDuration: 0.3) {
            self.toastView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.hideToast()
        }
    }
    
    public func showErrorView() {
        // Remove any existing error view
        errorView?.removeFromSuperview()
        
        // Create container view
        let containerView = UIView()
        containerView.backgroundColor = .white
        
        // Create stack view for content
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        
        // Create error image
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemRed
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
        }
        
        // Create error title
        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("browser.error.page.not.found.title", comment: "")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        
        // Create error message
        let messageLabel = UILabel()
        messageLabel.text = NSLocalizedString("browser.error.page.not.found.message", comment: "")
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .darkGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // Add views to stack
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        
        // Add stack to container
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        // Add container to view hierarchy
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalTo(webView)
        }
        
        errorView = containerView
    }

    public func hideErrorView() {
        errorView?.removeFromSuperview()
        errorView = nil
    }
    
    public func updateNavigationButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
}
