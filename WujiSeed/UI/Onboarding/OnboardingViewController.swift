//
//  OnboardingViewController.swift
//  WujiSeed
//
//  Main container for onboarding flow with swipe navigation
//

import UIKit

/// Full-screen onboarding controller with swipeable pages
class OnboardingViewController: UIViewController {

    // MARK: - Properties

    private let pages = OnboardingPageData.createAllPages()
    private var pageViews: [OnboardingPageView] = []
    private var currentPage: Int = 0

    /// Callback when onboarding is completed or skipped
    var onComplete: (() -> Void)?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.bounces = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = pages.count
        pc.currentPage = 0
        pc.pageIndicatorTintColor = Theme.Colors.borderGray
        pc.currentPageIndicatorTintColor = Theme.Colors.elegantBlue
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Lang("onboarding.skip"), for: .normal)
        button.setTitleColor(Theme.MinimalTheme.textSecondary, for: .normal)
        button.titleLabel?.font = Theme.Fonts.subtitle
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
        setupActions()

        // Register for language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewContentSize()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        view.addSubview(pageControl)
        // Skip button hidden - force users to view all pages on first install
        // view.addSubview(skipButton)

        scrollView.delegate = self

        // PageControl floats on top of scrollView (transparent background)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

                pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
                pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
                pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    }

    private func setupPages() {
        for (index, pageData) in pages.enumerated() {
            let pageView = OnboardingPageView(pageData: pageData)
            pageView.translatesAutoresizingMaskIntoConstraints = false

            // Handle start button tap on last page
            if pageData.pageType == .callToAction {
                pageView.onStartButtonTapped = { [weak self] in
                    self?.completeOnboarding()
                }
            }

            scrollView.addSubview(pageView)
            pageViews.append(pageView)

            // Position each page
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                pageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                pageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])

            if index == 0 {
                pageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            } else {
                pageView.leadingAnchor.constraint(equalTo: pageViews[index - 1].trailingAnchor).isActive = true
            }

            if index == pages.count - 1 {
                pageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            }
        }

        // Animate first page entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pageViews.first?.animateEntrance()
        }
    }

    private func setupActions() {
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
    }

    private func updateScrollViewContentSize() {
        // Content size is handled by constraints, but we need to update page positions
        for (index, pageView) in pageViews.enumerated() {
            pageView.frame = CGRect(
                x: CGFloat(index) * scrollView.bounds.width,
                y: 0,
                width: scrollView.bounds.width,
                height: scrollView.bounds.height
            )
        }
        scrollView.contentSize = CGSize(
            width: scrollView.bounds.width * CGFloat(pages.count),
            height: scrollView.bounds.height
        )
    }

    // MARK: - Actions

    @objc private func skipTapped() {
        completeOnboarding()
    }

    @objc private func pageControlTapped() {
        let page = pageControl.currentPage
        scrollToPage(page, animated: true)
    }

    @objc private func languageDidChange() {
        // Recreate pages with new language
        skipButton.setTitle(Lang("onboarding.skip"), for: .normal)

        // Remove old page views
        for pageView in pageViews {
            pageView.removeFromSuperview()
        }
        pageViews.removeAll()

        // Recreate pages
        setupPages()
        updateScrollViewContentSize()

        // Restore current page position
        scrollToPage(currentPage, animated: false)
    }

    // MARK: - Navigation

    private func scrollToPage(_ page: Int, animated: Bool) {
        let offset = CGFloat(page) * scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: animated)
    }

    private func completeOnboarding() {
        // Fade out animation
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false) {
                self.onComplete?()
            }
        }
    }

    private func updateSkipButtonVisibility() {
        // Hide skip button on last page (CTA page has its own button)
        let isLastPage = currentPage == pages.count - 1
        UIView.animate(withDuration: 0.2) {
            self.skipButton.alpha = isLastPage ? 0 : 1
        }
    }
}

// MARK: - UIScrollViewDelegate

extension OnboardingViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }

        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        let clampedIndex = max(0, min(pageIndex, pages.count - 1))

        if clampedIndex != currentPage {
            currentPage = clampedIndex
            pageControl.currentPage = currentPage
            updateSkipButtonVisibility()

            // Animate current page entrance
            pageViews[safe: currentPage]?.animateEntrance()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Ensure page control is synced
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.currentPage = pageIndex
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
