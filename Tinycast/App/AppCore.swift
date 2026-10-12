import AppKit

/// Single owner of every long-lived manager. Wired up once from the app delegate.
@MainActor
@Observable
final class AppCore {
    static let shared = AppCore()

    let launcherRanking: LauncherRankingStore
    let appIndex: AppIndex
    let customCommands = CustomCommandStore()
    let quicklinks = QuicklinkStore()
    @ObservationIgnored private(set) lazy var windowLayouts = WindowLayoutStore()
    @ObservationIgnored private(set) lazy var customWindowSizes = CustomWindowSizeStore()
    @ObservationIgnored private(set) lazy var rooms = RoomStore()
    @ObservationIgnored private(set) lazy var roomMinimums = RoomMinimumSizeStore()
    @ObservationIgnored private(set) lazy var roomParking = RoomParkingLedger(
        fileURL: AppPaths.applicationSupport().appendingPathComponent("room-parking.json"))
    @ObservationIgnored private(set) lazy var roomSession = RoomSession()
    let clipboardStore = ClipboardStore(openImmediately: false)
    @ObservationIgnored private var clipboardTextIndexer: ClipboardTextIndexer?
    let clipboardManager: ClipboardManager
    @ObservationIgnored private(set) lazy var snippetsStore =
        SnippetsStore(repository: Self.snippetsRepository(for: settings))
    @ObservationIgnored private(set) lazy var snippetListener = SnippetKeywordListener(
        syntheticEventTag: Paster.tinycastEventTag)
    let textInjector: TextInjector
    let hotKeys = HotKeyManager()
    @ObservationIgnored private(set) lazy var dictationAudioDucker = DictationAudioDucker()
    @ObservationIgnored private(set) lazy var dictationModels =
        DictationModelStore(idleRelease: settings.dictationIdleRelease)
    let hyperKeyTap = HyperKeyTap()
    let windowMover = WindowMover()
    let spaceSwitcher = SpaceSwitcher()
    let inputSourceSwitcher = InputSourceSwitcher()
    let settings: AppSettings
    /// Mirrors settings into settings.json; nil while the Backup pane's switch is off.
    @ObservationIgnored private var settingsFile: SettingsFileRepository?
    /// The file's launcher items, kept to apply a waiting record once its app is installed.
    @ObservationIgnored private var launcherSettingsFile: LauncherSettingsFile?
    @ObservationIgnored private var appearanceObservation: NSKeyValueObservation?
    /// The last verdict `trackChatRoute` acted on; nil until it has read one.
    @ObservationIgnored private var chatsRunTheirOwnTools: Bool?
    @ObservationIgnored private let iconStyle = IconStyleMonitor()
    let favorites = FavoritesStore()
    let visibility = VisibilityStore()
    let aliases = AliasStore()
    let fallbacks = FallbackStore()
    let calcHistory = CalculatorHistoryStore()
    let currencyRates = CurrencyRateStore()
    let regionNumberFormat = RegionNumberFormatMonitor()
    @ObservationIgnored private(set) lazy var calendarStore = CalendarStore()
    @ObservationIgnored private(set) lazy var meetingClock = MeetingClock()
    @ObservationIgnored private(set) lazy var updateChecker = UpdateCheckStore()
    @ObservationIgnored private(set) lazy var supportReminders = SupportReminderStore(settings: settings)
    @ObservationIgnored private(set) lazy var emojiIndex = EmojiIndex()
    @ObservationIgnored private(set) lazy var frequentEmoji = FrequentEmojiStore()
    @ObservationIgnored private(set) lazy var pinnedEmoji = PinnedEmojiStore()
    let runningApps = RunningAppsMonitor()
    let palette = PaletteState()
    let fileSearch = FileSearchSession()
    let dictionary = DictionarySession()
    let menuSearch = MenuSearchSession()
    let windowSwitch = WindowSwitchSession()
    let activationPolicy = ActivationPolicy()
    let uninstall = UninstallSession()
    @ObservationIgnored private(set) lazy var notesStore = NotesStore(
        repository: Self.notesRepository(for: settings),
        loadSelection: {
            UserDefaults.standard.string(forKey: "notesActiveFileName").map(NoteID.init(rawValue:))
        },
        saveSelection: { UserDefaults.standard.set($0?.rawValue, forKey: "notesActiveFileName") })
    @ObservationIgnored private(set) lazy var extensions = ExtensionManager(clipboardStore: clipboardStore)
    @ObservationIgnored private(set) lazy var chatHistory = ChatHistoryStore(
        directory: AppPaths.applicationSupport())
    @ObservationIgnored private(set) lazy var aiChats = AIChatSurfacesState(history: chatHistory)
    @ObservationIgnored private(set) lazy var aiSettings = AISettingsStore(
        environmentStore: .keychain,
        isAppleIntelligenceAvailable: { AppleIntelligenceProvider.status().isAvailable })
    @ObservationIgnored private(set) lazy var mcpSettings = MCPSettingsStore()
    @ObservationIgnored private(set) lazy var mcpOAuth = MCPOAuthManager()
    @ObservationIgnored private(set) lazy var mcp = MCPServerManager(oauth: mcpOAuth)
    @ObservationIgnored private(set) lazy var quickActionSettings = QuickActionSettingsStore()
    @ObservationIgnored private(set) lazy var customQuickActions = CustomQuickActionStore()
    @ObservationIgnored private(set) lazy var chatGPTSubscription = ChatGPTSubscriptionManager()
    @ObservationIgnored private(set) lazy var installedAI = InstalledAIManager()
    @ObservationIgnored private var appliedLaunchRevisions: [InstalledAIKind: Int] = [:]

    /// Set when a layout editor should open with Settings; the pane consumes it.
    var pendingWindowLayoutEdit: WindowLayoutEditRequest?
    var pendingExtensionStoreInstall: ExtensionDeepLink.StoreInstall?

    @ObservationIgnored private(set) lazy var snippetCoordinator = SnippetCoordinator(
        store: snippetsStore, listener: snippetListener, injector: textInjector,
        clipboardStore: clipboardStore, appIndex: appIndex, settings: settings,
        windowController: windowController, paletteCoordinator: paletteCoordinator,
        palette: palette,
        showMessage: { [unowned self] in self.showMessage($0, tone: $1) }, core: self)
    @ObservationIgnored private(set) lazy var dictationCoordinator = DictationCoordinator(
        settings: settings, hotKeys: hotKeys, models: dictationModels, injector: textInjector,
        audioDucker: dictationAudioDucker,
        confirmEnable: { [unowned self] in
            await self.confirm(
                title: "Enable Dictation?",
                message: "Tinycast needs microphone access for dictation and Accessibility to paste into "
                    + "other apps. Audio is processed on this Mac.",
                symbol: "waveform", confirmTitle: "Continue", tone: .neutral,
                confirmRole: .standard)
        },
        showMessage: { [unowned self] in self.showMessage($0, tone: $1) })
    @ObservationIgnored private(set) lazy var quicklinkCoordinator = QuicklinkCoordinator(
        store: quicklinks, settings: settings,
        appIndex: appIndex, injector: textInjector, hotKeys: hotKeys, favorites: favorites,
        visibility: visibility, ranking: launcherRanking, aliases: aliases,
        windowController: windowController,
        paletteCoordinator: paletteCoordinator,
        clipboardHistory: { NSPasteboard.general.string(forType: .string).map { [$0] } ?? [] },
        core: self)

    @ObservationIgnored private(set) lazy var paletteCoordinator = PaletteCoordinator(
        palette: palette, settings: settings, appIndex: appIndex,
        fileSearch: fileSearch, menuSearch: menuSearch, windowSwitch: windowSwitch,
        windowController: windowController)
    /// Its own window and lifecycle: neither coordinator shows or closes the other's surface.
    @ObservationIgnored private(set) lazy var settingsCoordinator = SettingsCoordinator(core: self)
    @ObservationIgnored private(set) lazy var onboardingCoordinator = OnboardingCoordinator(
        core: self)
    @ObservationIgnored private(set) lazy var systemActionCoordinator = SystemActionCoordinator(
        paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var uninstallCoordinator = UninstallCoordinator(
        session: uninstall, palette: palette, paletteCoordinator: paletteCoordinator,
        appIndex: appIndex, runningApps: runningApps, hotKeys: hotKeys, favorites: favorites,
        visibility: visibility, ranking: launcherRanking, aliases: aliases, core: self)
    @ObservationIgnored private(set) lazy var extensionCoordinator = ExtensionCoordinator(
        extensions: extensions, palette: palette, paletteCoordinator: paletteCoordinator,
        settingsCoordinator: settingsCoordinator, settings: settings, core: self)
    @ObservationIgnored private(set) lazy var windowCommandCoordinator = WindowCommandCoordinator(
        settings: settings, paletteCoordinator: paletteCoordinator, windowMover: windowMover,
        spaceSwitcher: spaceSwitcher, customSizes: customWindowSizes)
    @ObservationIgnored private(set) lazy var customWindowSizeCoordinator =
        CustomWindowSizeCoordinator(
            store: customWindowSizes, settings: settings, appIndex: appIndex, hotKeys: hotKeys,
            favorites: favorites, visibility: visibility, ranking: launcherRanking,
            aliases: aliases, core: self)
    @ObservationIgnored private(set) lazy var windowShortcutPresetCoordinator =
        WindowShortcutPresetCoordinator(hotKeys: hotKeys, core: self)
    @ObservationIgnored private(set) lazy var windowLayoutCoordinator = WindowLayoutCoordinator(
        store: windowLayouts, settings: settings, appIndex: appIndex, hotKeys: hotKeys,
        favorites: favorites, visibility: visibility, ranking: launcherRanking, aliases: aliases,
        paletteCoordinator: paletteCoordinator, settingsCoordinator: settingsCoordinator,
        core: self)
    @ObservationIgnored private(set) lazy var roomCoordinator = RoomCoordinator(
        store: rooms, minimums: roomMinimums, ledger: roomParking, session: roomSession,
        settings: settings, appIndex: appIndex, hotKeys: hotKeys, favorites: favorites,
        visibility: visibility, ranking: launcherRanking, aliases: aliases, palette: palette,
        paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var customCommandCoordinator = CustomCommandCoordinator(
        store: customCommands, settings: settings, appIndex: appIndex,
        paletteCoordinator: paletteCoordinator, settingsCoordinator: settingsCoordinator,
        hotKeys: hotKeys, favorites: favorites, visibility: visibility,
        ranking: launcherRanking, aliases: aliases, activationPolicy: activationPolicy, core: self)
    @ObservationIgnored private(set) lazy var appleShortcutCoordinator = AppleShortcutCoordinator(
        settings: settings, appIndex: appIndex, hotKeys: hotKeys, favorites: favorites,
        visibility: visibility, ranking: launcherRanking, aliases: aliases,
        paletteCoordinator: paletteCoordinator, core: self)
    /// Window state, not a preference: it rides `UserDefaults` like the active note's filename.
    private nonisolated static let noteFormattingBarKey = "notesFormattingBarExpanded"
    @ObservationIgnored private(set) lazy var notesCoordinator = NotesCoordinator(
        store: notesStore,
        settings: settings,
        appIndex: appIndex,
        core: self,
        isFormattingBarExpanded: UserDefaults.standard.bool(forKey: Self.noteFormattingBarKey),
        saveFormattingBarExpanded: {
            UserDefaults.standard.set($0, forKey: Self.noteFormattingBarKey)
        })

    @ObservationIgnored private(set) lazy var launcherCoordinator = LauncherCoordinator(
        ranking: launcherRanking, windowController: windowController,
        paletteCoordinator: paletteCoordinator, settingsCoordinator: settingsCoordinator,
        customCommandCoordinator: customCommandCoordinator, quicklinkCoordinator: quicklinkCoordinator,
        core: self)
    @ObservationIgnored private(set) lazy var fallbackCoordinator = FallbackCoordinator(
        store: fallbacks, quicklinks: quicklinks, settings: settings, visibility: visibility,
        core: self)
    @ObservationIgnored private(set) lazy var clipboardCoordinator = ClipboardCoordinator(
        clipboardStore: clipboardStore, clipboardManager: clipboardManager, settings: settings,
        appIndex: appIndex, palette: palette, windowController: windowController,
        paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var emojiCoordinator = EmojiCoordinator(
        frequentEmoji: frequentEmoji, settings: settings, windowController: windowController,
        paletteCoordinator: paletteCoordinator)
    @ObservationIgnored private(set) lazy var calculatorCoordinator = CalculatorCoordinator(
        calcHistory: calcHistory, paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var calendarCoordinator = CalendarCoordinator(
        store: calendarStore, clock: meetingClock, appIndex: appIndex, settings: settings,
        paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var fileSearchCoordinator = FileSearchCoordinator(
        settings: settings, appIndex: appIndex, session: fileSearch, palette: palette,
        paletteCoordinator: paletteCoordinator, windowController: windowController, core: self)
    @ObservationIgnored private(set) lazy var menuSearchCoordinator = MenuSearchCoordinator(
        settings: settings, appIndex: appIndex, session: menuSearch, palette: palette,
        paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var windowSwitchCoordinator = WindowSwitchCoordinator(
        settings: settings, appIndex: appIndex, session: windowSwitch, palette: palette,
        paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var cameraCoordinator = CameraCoordinator(core: self)
    @ObservationIgnored private(set) lazy var dictionaryCoordinator = DictionaryCoordinator(
        paletteCoordinator: paletteCoordinator)
    @ObservationIgnored private(set) lazy var updateCoordinator = UpdateCoordinator(
        store: updateChecker, core: self)
    @ObservationIgnored private(set) lazy var supportCoordinator = SupportCoordinator(
        store: supportReminders, core: self)
    @ObservationIgnored private(set) lazy var quickActionCoordinator = QuickActionCoordinator(
        settings: settings, store: quickActionSettings, customActions: customQuickActions,
        injector: textInjector, appIndex: appIndex, hotKeys: hotKeys, favorites: favorites,
        visibility: visibility, ranking: launcherRanking, aliases: aliases,
        paletteCoordinator: paletteCoordinator, core: self)
    @ObservationIgnored private(set) lazy var mcpCoordinator = MCPCoordinator(
        settings: settings, store: mcpSettings, manager: mcp, core: self)
    /// Its own window and lifecycle, like Settings; Quick AI is the palette's half of the feature.
    @ObservationIgnored private(set) lazy var aiChatCoordinator = AIChatCoordinator(
        chats: aiChats, settings: settings, appIndex: appIndex,
        paletteCoordinator: paletteCoordinator, settingsCoordinator: settingsCoordinator,
        core: self)
    @ObservationIgnored private(set) lazy var quickAICoordinator = QuickAICoordinator(
        chats: aiChats, settings: settings, palette: palette,
        paletteCoordinator: paletteCoordinator, core: self)

    @ObservationIgnored private lazy var windowController = PaletteWindowController(core: self)
    @ObservationIgnored private lazy var messageHUD = MessageHUDController(settings: settings)
    private(set) var isShowingDialog = false
    var isDimmingPaletteForDialog: Bool { isShowingDialog && windowController.isVisible }
    /// Every confirmation, report and prompt; it also stops a held hotkey stacking them.
    @ObservationIgnored private lazy var dialogs = DialogController(
        settings: settings,
        onPresentationChanged: { [weak self] isPresenting in
            guard let self else { return }
            isShowingDialog = isPresenting
        })
    private let healthTicker = HealthTicker()

    private init() {
        let launcherRanking = LauncherRankingStore()
        let settings = AppSettings()
        self.launcherRanking = launcherRanking
        self.settings = settings
        appIndex = AppIndex(ranking: launcherRanking, aliases: aliases)
        let clipboardManager = ClipboardManager(store: clipboardStore, settings: settings)
        self.clipboardManager = clipboardManager
        textInjector = TextInjector(clipboardManager: clipboardManager, settings: settings)
    }

    func start() {
        UserDefaults.standard.register(defaults: ["NSInitialToolTipDelay": 250])
        NSApp.setActivationPolicy(.accessory)
        applyAppearance()
        observeEffectiveAppearance()
        appIndex.start(settings: settings)
        customCommands.onChange = { [weak self] _ in
            self?.customCommandCoordinator.applyCustomCommandsPresence()
        }
        customCommandCoordinator.applyCustomCommandsPresence()
        quicklinks.onChange = { [weak self] _ in self?.quicklinkCoordinator.applyQuicklinksPresence() }
        quicklinks.load()
        if !OnboardingState.hasOnboarded, quicklinks.quicklink(id: WebAI.quicklinkID) == nil {
            do {
                _ = try quicklinks.add(
                    Quicklink(
                        id: WebAI.quicklinkID, name: "网页 AI", link: WebAI.template(site: WebAI.defaultSite),
                        iconSymbol: "sparkles"))
            } catch { showMessage("无法创建网页 AI 入口，请在设置中重试。", tone: .danger) }
        }
        quicklinkCoordinator.applyQuicklinksPresence()
        appleShortcutCoordinator.applyPresence()
        paletteCoordinator.onLauncherShown = { [weak self] in self?.appleShortcutCoordinator.refresh() }
        appIndex.onScan = { [weak self] in
            guard let self else { return }
            hotKeys.removeAppBindings(where: appIndex.isUninstalled)
            if settings.settingsFileEnabled, settingsFile == nil {
                startSettingsFile(importing: true)
            } else if let launcherSettingsFile {
                reportSettingsFileIssues(launcherSettingsFile.applyInstalled())
            }
        }
        hyperKeyTap.healthTicker = healthTicker
        hotKeys.modifierTapMonitor.healthTicker = healthTicker
        hotKeys.onTogglePalette = { [weak self] in self?.paletteCoordinator.togglePalette() }
        hotKeys.onRunCommand = { [weak self] in self?.launcherCoordinator.runCommand($0) }
        hotKeys.onRunCustomCommand = { [weak self] in self?.customCommandCoordinator.runCustomCommand(id: $0)
        }
        hotKeys.onOpenQuicklink = { [weak self] in self?.quicklinkCoordinator.openQuicklink(id: $0) }
        hotKeys.onRunAppleShortcut = { [weak self] in self?.appleShortcutCoordinator.run(id: $0) }
        hotKeys.displayName = { [weak self] in self?.hotKeyDisplayName(for: $0) }
        hotKeys.allowsAction = { [weak self] action in
            guard let self, ProductProfile.allowsHotKey(action.defaultsKey),
                visibility.allowsHotKey(action)
            else { return false }
            if case .command(let id) = action { return appIndex.isCommandEnabled(id) }
            return true
        }
        KeyShortcut.displayedHyperChord = { [settings] in
            guard settings.hyperKey != .none else { return nil }
            return KeyShortcut.hyperChord(includesShift: settings.hyperKeyIncludesShift)
        }
        hotKeys.start(
            customCommandIDs: Set(customCommands.commands.map(\.id)),
            quicklinkIDs: Set(quicklinks.quicklinks.map(\.id)),
            windowLayoutIDs: [], windowRoomIDs: [], customWindowSizeIDs: [], quickActionIDs: [])
        hyperKeyTap.start(settings: settings)
        observeFeatureSwitches()
        Task { await appIndex.refresh() }
        if !OnboardingState.hasOnboarded {
            OnboardingState.markShown()
            onboardingCoordinator.showOnboarding()
        }
    }

    /// Clicking the Dock icon: raise whichever window is already open, else summon the launcher.
    func handleReopen() {
        if settingsCoordinator.focusExisting() { return }
        if onboardingCoordinator.focusExisting() { return }
        if customCommandCoordinator.focusOutputWindow() { return }
        paletteCoordinator.showPalette(mode: .launcher, restoreAnyMode: true)
    }

    func handleOpenURL(_ url: URL) {
        guard url.scheme == "tinycast-custom", url.host == "open" else { return }
        paletteCoordinator.showPalette(mode: .launcher)
    }

    /// The store-backed half of the conflict message; `HotKeyManager` names the catalogs itself.
    private func hotKeyDisplayName(for action: HotKeyAction) -> String? {
        switch action {
        case .app(let bundleID):
            return appIndex.apps.first { $0.kind == .application && $0.bundleID == bundleID }?.name
        case .settingsPane(let bundleID):
            return appIndex.apps.first { $0.kind == .systemSettings && $0.bundleID == bundleID }?
                .name
        case .customCommand(let id):
            return customCommands.command(id: id)?.name
        case .quicklink(let id):
            return quicklinks.quicklink(id: id)?.name
        case .quickAction(let id):
            return customQuickActions.action(id: id)?.name
        case .windowLayout(let id):
            return windowLayouts.layout(id: id)?.name
        case .windowRoom(let id):
            return rooms.room(id: id)?.name
        case .customWindowSize(let id):
            return customWindowSizes.size(id: id)?.name
        case .appleShortcut(let id):
            return appleShortcutCoordinator.name(of: id)
        case .snippet(let id):
            return snippetsStore.record(id: id)?.snippet.name
        case .extensionCommand(let entryID):
            return appIndex.apps.first { $0.kind == .extensionCommand && $0.id == entryID }?.name
        case .togglePalette, .dictation, .command, .systemAction, .windowCommand:
            return nil
        }
    }

    func flushNotesForTermination() async {}

    func stopDictationForTermination() async {}

    /// Idempotent: both switches are tracked, and either one flipping re-runs the whole decision.
    func applyClipboardTextSearch() {
        guard settings.clipboardEnabled, settings.clipboardTextSearchEnabled else {
            clipboardStore.onItemsChanged = nil
            clipboardStore.onSearchResultsChanged = nil
            clipboardStore.setTextSearchEnabled(false)
            clipboardTextIndexer?.stop()
            return
        }
        guard clipboardStore.setTextSearchEnabled(true) else {
            showMessage("Couldn't enable text recognition for clipboard history.", tone: .danger)
            return
        }
        clipboardStore.setTextSearchActive(palette.isVisible)
        // Kept across a disable: the indexer reschedules itself once a cancelled run winds down.
        let indexer =
            clipboardTextIndexer
            ?? ClipboardTextIndexer(store: clipboardStore, canRun: { ClipboardTextIndexer.isSystemIdle })
        clipboardTextIndexer = indexer
        clipboardStore.onItemsChanged = { [weak indexer] in indexer?.schedule() }
        clipboardStore.onSearchResultsChanged = { [weak self] query, previous, current in
            self?.clipboardCoordinator.followSearchResults(query: query, previous: previous, current: current)
        }
        indexer.start()
    }

    func prepareForTermination() {
        settingsFile?.flush()
        hyperKeyTap.prepareForTermination()
        inputSourceSwitcher.endSession()
        textInjector.prepareForTermination()
    }

    /// Only the tool whose own path or variables changed is checked again; the rest keep running.
    private func applyInstalledLaunches() {
        let revisions = aiSettings.launchRevisions
        let enabled =
            settings.aiEnabled || settings.quickActionsEnabled
            ? aiSettings.enabledInstalledProviders : []
        for kind in InstalledAIKind.allCases where appliedLaunchRevisions[kind] != revisions[kind] {
            guard enabled.contains(kind) else { continue }
            if kind == .codex {
                chatGPTSubscription.stop()
                chatGPTSubscription.refresh()
            } else {
                installedAI.refresh(kind: kind)
            }
        }
        appliedLaunchRevisions = revisions
    }

    @discardableResult
    func applyInstalledAILifecycle() -> Task<Void, Never> {
        let enabledKinds =
            settings.aiEnabled || settings.quickActionsEnabled
            ? aiSettings.enabledInstalledProviders : []
        var tasks: [Task<Void, Never>] = []
        if enabledKinds.contains(.codex) {
            tasks.append(
                chatGPTSubscription.phase == .idle
                    ? chatGPTSubscription.refresh()
                    : chatGPTSubscription.currentRefreshTask())
        } else {
            chatGPTSubscription.stop()
        }
        tasks.append(installedAI.ensure(enabledKinds: enabledKinds))
        return Task { for task in tasks { await task.value } }
    }

    /// Permissive guardrails: the text transformed is the reader's own, which `.default` refuses.
    func quickActionProvider(for action: QuickAction) throws -> any AIProvider {
        quickActionSettings.repairModel(
            against: aiSettings.connections, fallback: aiSettings.defaultModel)
        guard let selection = quickActionSettings.model(for: action) ?? aiSettings.defaultModel
        else {
            throw AIProviderError.unavailable("Choose a model in Settings \u{2192} Quick Actions.")
        }
        return try AIProviderFactory.make(
            selection: selection, settings: aiSettings, subscription: chatGPTSubscription,
            installedAI: installedAI,
            guardrails: .permissiveContentTransformations)
    }

    // MARK: - Feature switches

    private func observeFeatureSwitches() {
        track(
            {
                _ = $0.customCommandsEnabled; _ = $0.customCommandsShowInLauncher
            },
            reproject: { $0.customCommandCoordinator.applyCustomCommandsPresence() })
        track(
            {
                _ = $0.quicklinksEnabled; _ = $0.quicklinksShowInLauncher
            },
            reproject: { $0.quicklinkCoordinator.applyQuicklinksPresence() })
        track({ _ = $0.appleShortcutsEnabled }, reproject: { $0.appleShortcutCoordinator.applyPresence() })
        track({ _ = $0.hyperKeyIncludesShift }, reproject: { $0.applyHyperChord() })
        track({ _ = $0.appearance }, reproject: { $0.applyAppearance() })
        track({ _ = $0.interfaceSize }, reproject: { $0.windowController.applyInterfaceSize() })
    }

    /// `.system` resolves to `nil`, so AppKit follows macOS with nothing polling.
    private func applyAppearance() {
        NSApp.appearance = settings.appearance.nsAppearance
    }

    /// IconCache is told here, not from `applyAppearance()`, which never fires under `.system`.
    private func observeEffectiveAppearance() {
        // Synchronous on main, so no row can cache a tile under the outgoing appearance's key.
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.initial]) { app, _ in
            MainActor.assumeIsolated { IconCache.setDarkSurface(app.effectiveAppearance.isDark) }
        }
    }

    private func track(
        _ reads: @escaping @Sendable @MainActor (AppSettings) -> Void,
        reproject: @escaping @Sendable @MainActor (AppCore) -> Void
    ) {
        track(settings, reads, reproject: reproject)
    }

    /// Fires synchronously on main before the write lands, so the task re-arms and re-reads.
    private func track<Store: AnyObject & Sendable>(
        _ store: Store,
        _ reads: @escaping @Sendable @MainActor (Store) -> Void,
        reproject: @escaping @Sendable @MainActor (AppCore) -> Void
    ) {
        withObservationTracking {
            reads(store)
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.track(store, reads, reproject: reproject)
                reproject(self)
            }
        }
    }

    /// A chat route that runs its own MCP client decides which servers Tinycast runs itself.
    private func trackChatRoute() {
        let runsOwnTools = withObservationTracking {
            aiChatCoordinator.everyChatRunsItsOwnTools
        } onChange: { [weak self] in
            Task { @MainActor in self?.trackChatRoute() }
        }
        // Re-read on every streaming flush, so only a changed verdict reaches the servers.
        defer { chatsRunTheirOwnTools = runsOwnTools }
        guard let previous = chatsRunTheirOwnTools, previous != runsOwnTools else { return }
        mcpCoordinator.applyEnabled()
    }

    /// Without a Hyper key the chord means nothing, so a literal ⌃⌥⌘ combo is left as recorded.
    private func applyHyperChord() {
        guard settings.hyperKey != .none else { return }
        hotKeys.retargetHyperBindings(includesShift: settings.hyperKeyIncludesShift)
    }

    private func applySnippetsFolder() {
        let repository = Self.snippetsRepository(for: settings)
        Task { await snippetsStore.relocate(to: repository) }
    }

    private func applyNotesFolder() {
        let repository = Self.notesRepository(for: settings)
        Task { await notesStore.relocate(to: repository) }
    }

    private static func snippetsRepository(for settings: AppSettings) -> SnippetRepository {
        SnippetRepository(
            snippetsDirectory: AppPaths.contentFolder(settings.snippetsFolder, named: "Snippets"))
    }

    private static func notesRepository(for settings: AppSettings) -> NotesRepository {
        NotesRepository(notesDirectory: AppPaths.contentFolder(settings.notesFolder, named: "Notes"))
    }

    private func applyWindowCommandsPresence() {
        let visible = settings.windowManagementEnabled && settings.windowManagementShowInLauncher
        appIndex.setWindowCommandsVisible(visible)
    }

    // MARK: - Settings file

    /// Mirrors settings into settings.json from now on; `importing` applies the file's own first.
    func startSettingsFile(importing: Bool) {
        guard settingsFile == nil else { return }
        let shortcuts = HotKeySettingsFile(hotKeys: hotKeys)
        let launcher = LauncherSettingsFile(
            appIndex: appIndex, aliases: aliases, visibility: visibility, shortcuts: shortcuts)
        let file = SettingsFileRepository(
            fileURL: AppPaths.settingsFile(),
            bindings: SettingsFileSchema.bindings(
                settings: settings, ai: aiSettings, quickActions: quickActionSettings,
                shortcuts: shortcuts, launcher: launcher,
                windowManagement: WindowManagementSettingsFile(
                    sizes: customWindowSizes, layouts: windowLayouts, rooms: rooms, aliases: aliases,
                    shortcuts: shortcuts)),
            commit: shortcuts.commit)
        file.onIssues = { [weak self] issues in self?.reportSettingsFileIssues(issues) }
        settingsFile = file
        launcherSettingsFile = launcher
        settings.settingsFileEnabled = true
        file.start(importing: importing)
    }

    /// Stops the mirror; the file stays on disk as last written.
    func stopSettingsFile() {
        settingsFile?.flush()
        settingsFile = nil
        launcherSettingsFile = nil
        settings.settingsFileEnabled = false
    }

    private func reportSettingsFileIssues(_ issues: [SettingsFileIssue]) {
        guard let summary = SettingsFileIssue.summary(issues) else { return }
        showMessage(summary, tone: .danger)
    }

    // MARK: - Interruption

    /// What the app is in the middle of; the update prompt and the support reminder both ask first.
    var currentActivity: UpdateActivity {
        UpdateActivity(
            isExpandingSnippet: textInjector.isDelivering,
            isRunningExtension: extensions.running != nil,
            isUninstalling: uninstall.isTrashing,
            isRecordingHotKey: hotKeys.recordingAction != nil,
            isShowingDialog: isShowingDialog,
            isPaletteVisible: paletteCoordinator.isVisible)
    }

    /// Whether a window may take focus without interrupting something the user started.
    var canInterruptUser: Bool { UpdateReadiness.evaluate(currentActivity) == nil }

    // MARK: - Dialogs, routed here so `dialogs` stays the single owner

    func showNotice(title: String, message: String, symbol: String, tone: DialogTone) async {
        await dialogs.notice(title: title, message: message, symbol: symbol, tone: tone)
    }

    /// `tone` styles the glyph, `confirmRole` the button; separate on purpose.
    func confirm(
        title: String, message: String?, symbol: String?, confirmTitle: String,
        tone: DialogTone = .danger, confirmRole: DialogAction.Role = .destructive,
        dismissTitle: String = "Cancel"
    ) async -> Bool {
        await dialogs.confirm(
            title: title, message: message, symbol: symbol, tone: tone, confirmTitle: confirmTitle,
            confirmRole: confirmRole, dismissTitle: dismissTitle)
    }

    /// A question with more than two answers; the returned index is into `options`.
    func choose(
        title: String, message: String?, symbol: String?, options: [DialogAction],
        defaultIndex: Int, tone: DialogTone = .neutral
    ) async -> Int {
        await dialogs.choose(
            title: title, message: message, symbol: symbol, tone: tone, options: options,
            defaultIndex: defaultIndex)
    }

    /// A failure with one usable second option; `true` when the user takes it.
    func reportFailure(
        title: String, message: String, symbol: String, recovery: String?
    ) async
        -> Bool
    {
        await dialogs.reportFailure(
            title: title, message: message, symbol: symbol, recovery: recovery)
    }

    /// The transient success/info pill, so `messageHUD` stays single-owned alongside `dialogs`.
    func showMessage(_ message: String, tone: DialogTone = .success) {
        messageHUD.show(message: L10n.tr(message), tone: tone)
    }

    /// The same pill with a spinner, for work the reader started and cannot otherwise see running.
    func showProgress(_ message: String, onCancel: (() -> Void)? = nil) {
        messageHUD.showProgress(message: L10n.tr(message), onCancel: onCancel)
    }

    func hideProgress() {
        messageHUD.dismiss()
    }

    /// The volume slider, so `dialogs` stays the single owner of every prompt in the app.
    func pickVolume(current: Float32) async -> Float32? {
        await dialogs.pickVolume(current: current)
    }

    /// The snippet argument prompt, for the same reason.
    func fillSnippetArguments(
        snippetName: String, arguments: [SnippetTemplateEngine.MissingArgument]
    ) async -> [String: String]? {
        await dialogs.fillSnippetArguments(snippetName: snippetName, arguments: arguments)
    }
}
