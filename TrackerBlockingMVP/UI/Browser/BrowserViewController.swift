//
//  BrowserViewController.swift
//  TrackerBlockingMVP
//
//  Created by FC on 24/2/25.
//

import UIKit
@preconcurrency import WebKit
import SnapKit
import Combine

class BrowserViewController: UIViewController, UITextFieldDelegate {
    private(set) public var rootView = BrowserView()
    private let viewModel: BrowserViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    private let contentBlockerManager: ContentBlockerProtocol
    private var isUpdateBlockingRulesInProgress = false
    private var currentDomain: String = ""
    private static let remoteTestPageURLString = "https://tracker-test.local/"
    private let ruleCache: RuleCacheProtocol
    private let allowListManager: AllowlistManagerProtocol
    private var areRulesReady = false
    private var pendingURLToLoad: URL?

    // MARK: - Lifecycle
    public init(with viewModel: BrowserViewModelProtocol,
                contentBlockerManager: ContentBlockerProtocol,
                ruleCache: RuleCacheProtocol = RuleCache(),
                allowListManager: AllowlistManagerProtocol) {
        self.viewModel = viewModel
        self.contentBlockerManager = contentBlockerManager
        self.ruleCache = ruleCache
        self.allowListManager = allowListManager
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        loadBlockingRules { [weak self] in
            self?.areRulesReady = true
            var targetURL = URL(string: "https://duckduckgo.com")
            if let pendingURLToLoad = self?.pendingURLToLoad {
                targetURL = pendingURLToLoad
            }
            if let targetURL = targetURL {
                self?.loadURL(targetURL)
            }
        }
     }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = NSLocalizedString("browser.title", comment: "")
        view.addSubview(rootView)
        rootView.snp.makeConstraints {
            $0.edges.equalTo(self.view.safeAreaLayoutGuide)
        }
    }
    
    private func setupBindings() {
        rootView.urlField.delegate = self
        rootView.webView.navigationDelegate = self
        
        rootView.didTapOnPrivacyActionButton = { [weak self] in
            guard
                let self = self,
                !self.isUpdateBlockingRulesInProgress,
                !self.currentDomain.isEmpty
            else { return }
            
            self.managePrivacySettings()
        }
        
        rootView.didTapOnTestActionButton = { [weak self] in
            // Show confirmation alert
            let alert = UIAlertController(
                title: NSLocalizedString("browser.alert.test.tracking.title", comment: ""),
                message: NSLocalizedString("browser.alert.test.tracking.msg", comment: ""),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Run Test", style: .default) { [weak self] _ in
                self?.loadTrackerTestPage()
            })
            
            self?.present(alert, animated: true)
        }
        
        rootView.webView
            .publisher(for: \.isLoading)
            .sink { [weak self] isLoading in
                // Update UI based on loading state
                if !isLoading {
                    self?.rootView.updateNavigationButtons()
                }
            }
            .store(in: &cancellables)
        
        // Observe the WebView's navigation history to update buttons
        rootView.webView
            .publisher(for: \.canGoBack)
            .sink { [weak self] _ in
                self?.rootView.updateNavigationButtons()
            }
            .store(in: &cancellables)
        
        rootView.webView
            .publisher(for: \.canGoForward)
            .sink { [weak self] _ in
                self?.rootView.updateNavigationButtons()
            }
            .store(in: &cancellables)
    }
    
    private func loadBlockingRules(completion: @escaping () -> Void = {}) {
        if let cachedRules = ruleCache.getCachedRules() {
            rootView.setPrivacyButtonState(enable: true)
            applyContentRuleList(rulesJSON: cachedRules.rulesJSON, etag: cachedRules.etag)
            completion()
        } else {
            rootView.setPrivacyButtonState(enable: false)
            isUpdateBlockingRulesInProgress = true
        }

        viewModel
            .fetchTrackerData()
            .subscribe(on: DispatchQueue.global(qos: .background))
            .retry(2)
            .flatMap { [weak self] model -> DDGOPublisher<(String, String?)> in
                guard let self = self else { return Fail(error: GeneralError.unexpectedValue).eraseToAnyPublisher() }
                return self
                    .viewModel.generateRules(from: model.data, allowlist: [])
                    .map { rules in
                        return (rules, model.etagIdentifier)
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                    case .finished: break
                    case .failure(let error):
                        // Leave with a simple print for the MVP
                        print("Error: \(error)")
                }
                self?.rootView.setPrivacyButtonState(enable: true)
                self?.isUpdateBlockingRulesInProgress = false
            } receiveValue: { [weak self] (rules, etag) in
                do {
                    try self?.ruleCache.storeCachedRules(rulesJSON: rules, etag: etag)
                    self?.applyContentRuleList(rulesJSON: rules, etag: etag)
                    self?.checkCurrentDomainAllowlistStatus()
                } catch {
                    // Handle storage failure
                    // Leave with a simple print for the MVP
                    print("Failed to store cached rules: \(error)")
                }
                completion()
            }
            .store(in: &cancellables)
    }
    
    private func applyContentRuleList(rulesJSON: String, etag: String?) {
        contentBlockerManager.compileAndApplyContentRuleList(rulesJSON: rulesJSON, etag: etag, webView: rootView.webView) { error in
            if let error = error {
                // Leave with a simple print for the MVP
                print(error)
            }
        }
    }
    
    private func checkCurrentDomainAllowlistStatus() {
        // Check current domain's allowlist status after rules are applied
        if !currentDomain.isEmpty {
            let isAllowed = allowListManager.isAllowlisted(domain: currentDomain)
            rootView.setPrivacyButtonState(enable: !isAllowed)
        } else {
            // If no domain yet, default to enabled
            rootView.setPrivacyButtonState(enable: true)
        }
    }
    
    private func loadURL(_ url: URL) {
        guard areRulesReady else {
            rootView.showToast(message: NSLocalizedString("browser.loading.rules", comment: ""))
            pendingURLToLoad = url
            return
        }

        currentDomain = url.host ?? ""
        checkUISettings(url)
        rootView.webView.load(URLRequest(url: url))
    }

    private func checkUISettings(_ url: URL) {
        if url.absoluteString == BrowserViewController.remoteTestPageURLString {
            title = NSLocalizedString("browser.test.tracking.title", comment: "")
        } else {
            title = NSLocalizedString("browser.title", comment: "")
        }
        
        // Update button state based on current domain's allowlist status
        let isAllowed = allowListManager.isAllowlisted(domain: currentDomain)
        rootView.setPrivacyButtonState(enable: !isAllowed)
    }
    
    private func managePrivacySettings() {
        let isProtectionDisabled = allowListManager.toggleAllowlist(domain: currentDomain)
        
        // Update the UI to reflect the new protection state
        rootView.setPrivacyButtonState(enable: !isProtectionDisabled)
        
        if isProtectionDisabled {
            // Protection is turned off - remove content blocking rules
            rootView.webView.configuration.userContentController.removeAllContentRuleLists()
            
            // Show a toast message
            rootView.showToast(message: String(format: NSLocalizedString("tracker.blocking.disabled.title", comment: ""), currentDomain))
        } else {
            // Protection is turned on - reapply content blocking rules
            reapplyContentBlockingRules()
            
            // Show a toast message
            rootView.showToast(message: String(format: NSLocalizedString("tracker.blocking.enabled.title", comment: ""), currentDomain))
        }
        
        // Reload the current page to apply/remove rules
        if let url = self.rootView.webView.url {
            self.rootView.webView.load(URLRequest(url: url))
        }
    }
    
    private func loadTrackerTestPage() {
        guard let testPageURL = Bundle.main.url(forResource: "tracker-test", withExtension: "html") else {
            rootView.showToast(message: NSLocalizedString("tracker.blocking.page.not.found", comment: ""))
            return
        }
        
        allowListManager.removeFromAllowlist(domain: "tracker-test.local")
        currentDomain = BrowserViewController.remoteTestPageURLString
        
        rootView.webView.configuration.userContentController.removeAllScriptMessageHandlers()
        rootView.webView.loadFileURL(testPageURL, allowingReadAccessTo: Bundle.main.bundleURL)

        rootView.urlField.text = currentDomain
        rootView.showToast(message: NSLocalizedString("browser.test.tracking.msg", comment: ""))
    }

    private func reapplyContentBlockingRules(additionalBlockedDomains: Set<String>? = nil) {
        // Use cached rules if they exist and are less than 30 minutes old
        if let cached = ruleCache.getMostRecentRules(),
           Date().timeIntervalSince(cached.timestamp) < 1800 {
            
            let currentAllowlist = Set(allowListManager.getAllowlist())
            let mergedAllowlist = currentAllowlist.subtracting(additionalBlockedDomains ?? [])

            viewModel
                .generateRules(from: cached.rulesJSON.data(using: .utf8) ?? Data(),
                               allowlist: mergedAllowlist)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error generating rules: \(error)")
                    }
                }, receiveValue: { [weak self] rulesJSON in
                    self?.applyContentRuleList(rulesJSON: rulesJSON, etag: cached.etag)
                })
                .store(in: &cancellables)
        } else {
            loadBlockingRules()
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let inputText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !inputText.isEmpty else {
            return false
        }
        
        if let url = URL(string: inputText), url.scheme != nil {
            loadURL(url)
            return true
        }

        // Check if it's a URL without scheme (example.com or www.example.com)
        if inputText.contains(".") && !inputText.contains(" ") {
            let urlWithScheme = "https://" + inputText
            if let url = URL(string: urlWithScheme) {
                loadURL(url)
                return true
            }
        }

        // Not a valid URL or domain, create search URL
        let searchQuery = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let searchURL = URL(string: "https://duckduckgo.com/?t=h_&q=\(searchQuery)") {
            loadURL(searchURL)
            return true
        }
        
        // Fallback for any unexpected cases
        if let fallbackURL = URL(string: "https://duckduckgo.com") {
            loadURL(fallbackURL)
        }
        
        return true
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        .allow
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        print(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // URL failed to load - show error view
        rootView.showErrorView()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url, currentURL.lastPathComponent != "tracker-test.html" {
            rootView.urlField.text = currentURL.absoluteString
        }
        
        rootView.updateNavigationButtons()
        rootView.hideErrorView()

        // Update current domain and button state
        if let host = webView.url?.host {
            currentDomain = host
            let isAllowed = allowListManager.isAllowlisted(domain: currentDomain)
            rootView.setPrivacyButtonState(enable: !isAllowed)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        // Update navigation buttons when starting to load
        rootView.updateNavigationButtons()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        // Update navigation buttons when the page starts rendering
        rootView.updateNavigationButtons()
    }
}

// Extension to BrowserViewController to implement AllowlistViewControllerDelegate
extension BrowserViewController: AllowlistViewControllerDelegate {
    func allowlistDidUpdate(blockedDomains: Set<String>) {
        // Reapply content blocking rules, passing the blocked domains
        reapplyContentBlockingRules(additionalBlockedDomains: blockedDomains)
        
        // Reload the current page if it's in the blocked domains
        if let currentURL = rootView.webView.url,
           let host = currentURL.host,
           blockedDomains.contains(host) {
            rootView.webView.load(URLRequest(url: currentURL))
        }
        
        // Update the current domain's privacy button state
        checkCurrentDomainAllowlistStatus()
    }
}

extension BrowserViewController {
    public static func compose(allowListManager: AllowlistManagerProtocol) -> BrowserViewController {
        let trackerDataSetURL = URL(string: "https://staticcdn.duckduckgo.com/trackerblocking/v2.1/tds.json")!
        
        // Create a simplified ContentBlockerProtocol adapter that uses our service
        let contentBlockerAdapter = TrackerBlockerAdapter(with: allowListManager)
        
        // Create the ViewModel (keeping your existing approach)
        let httpClient = URLSessionHTTPClient()
        let etagDecorator = ETagDecorator(decoratee: httpClient, etagStorage: EtagStorage())
        let dataFetcher = TrackerDataFetcher(httpClient: etagDecorator, trackerDataURL: trackerDataSetURL, storage: TrackerDataStorage())
        let viewModel = BrowserViewModel(with: TrackerRulesGenerator(), dataFetcher: dataFetcher)
        
        return BrowserViewController(with: viewModel,
                                     contentBlockerManager: contentBlockerAdapter,
                                     allowListManager: allowListManager)
    }
}
