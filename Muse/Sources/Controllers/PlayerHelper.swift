//
//  PlayerHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

// Defines a set of infos to inform the VC
// about player events from the outside
enum PlayerAction: Int {
    case play
    case pause
    case previous
    case next
    case shuffling
    case repeating
    case scrubbing
    case like
    
    @available(OSX 10.12.2, *)
    var image: NSImage? {
        switch self {
        case .play:
            return .play
        case .pause:
            return .pause
        case .previous:
            return .previous
        case .next:
            return .next
        case .shuffling:
            return .shuffling
        case .repeating:
            return .repeating
        case .like:
            return .like
        default:
            return nil
        }
    }
    
    @available(OSX 10.12.2, *)
    var smallImage: NSImage? {
        switch self {
        case .play:
            return image?.resized(to: NSMakeSize(8, 8))
        case .pause:
            return image?.resized(to: NSMakeSize(7, 7))
        case .previous:
            return image?.resized(to: NSMakeSize(12, 12))
        case .next:
            return image?.resized(to: NSMakeSize(12, 12))
        case .shuffling, .repeating:
            return image?.resized(to: NSMakeSize(20, 20))
        case .like:
            return image?.resized(to: NSMakeSize(15, 15))
        default:
            return image
        }
    }
}

// Enum for the three possible player states
enum PlayerState {
    case stopped, paused, playing
}

struct PlayerHelperNotification {
    
    static private let name = Notification.Name("museHelperNotification")
    
    static private let helperNotificationKey = "helperNotification"
    
    // Supported player helper events
    enum Event {
        case playPause
        case nextTrack
        case previousTrack
        case scrub(Bool, Double?)
        case shuffling(Bool)
        case repeating(Bool)
        case like(Bool)
    }
    
    // The event associated with the notification
    let event: Event
    
    init(_ event: Event) {
        self.event = event
    }
    
    /**
     Posts the notification of the specified event
     */
    func post() {
        NotificationCenter.default.post(
            name: PlayerHelperNotification.name,
            object: nil,
            userInfo: [PlayerHelperNotification.helperNotificationKey: self])
    }
    
    /**
     Sets up an observer for the specified event
     executing the given closure
     */
    static func observe(block: @escaping (Event) -> ()) {
        NotificationCenter.default.addObserver(
            forName: name,
            object: nil,
            queue: nil)
        { notification in
            if let helperNotification = notification.userInfo?[helperNotificationKey] as? PlayerHelperNotification {
                block(helperNotification.event)
            }
        }
    }
}

protocol PlayerHelper {
    
    // MARK: Player features
    
    var doesSendPlayPauseNotification: Bool { get }
    
    var supportsLiking: Bool { get }
    
    // MARK: Song data
    
    var song: Song { get }
    
    // MARK: Playback controls
    
    func play()
    
    func pause()
    
    func togglePlayPause()
    
    func nextTrack()
    
    func previousTrack()
    
    // MARK: Playback status
    
    var playerState: PlayerState { get }
    
    var playbackPosition: Double { set get }
    
    var trackDuration: Double { get }
    
    func scrub(to doubleValue: Double?, touching: Bool)
    
    // MARK: Playback options
    
    var volume: Int { set get }
    
    var repeating: Bool { set get }
    
    var shuffling: Bool { set get }
    
    // MARK: Artwork
    
    func artwork() -> Any?
    
    // MARK: Starring
    
    var liked: Bool { set get }
    
    // MARK: Callbacks
    
    var playPauseHandler: () -> () { set get }
    
    var trackChangedHandler: (Bool) -> () { set get }
    
    var timeChangedHandler: (Bool, Double?) -> () { set get }
    
    var shuffleRepeatChangedHandler: (Bool, Bool) -> () { set get }
    
    var likeChangedHandler: (Bool) -> () { set get }
    
    // MARK: Application identifier
    
    static var BundleIdentifier: String { get }
    
    // MARK: Notification ID
    
    static var rawTrackChangedNotification: String { get }
    
}

extension PlayerHelper {
    
    // MARK: Player availability
    
    var isAvailable: Bool {
        // Returns if the application is running
        return NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.BundleIdentifier).count > 0
    }
    
    // MARK: Playback status
    
    var isPlaying: Bool {
        // Returns if the player is playing a track
        return playerState == .playing
    }
    
    func scrub(to doubleValue: Double? = nil, touching: Bool = false) {
        // Override this in extension to provide default args
        self.scrub(to: doubleValue, touching: touching)
        
        PlayerHelperNotification(.scrub(touching, doubleValue)).post()
    }
    
    // MARK: App data
    
    var name: String? {
        // Returns the name of the application
        // return application.name
        return Bundle.init(identifier: Self.BundleIdentifier)?
            .object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }
    
    var path: String? {
        // Returns the path of the player application
        return NSWorkspace.shared()
            .absolutePathForApplication(withBundleIdentifier: Self.BundleIdentifier)
    }
    
    var icon: NSImage? {
        guard let path = path else { return nil }
        
        // Returns the icon of the player application
        return NSWorkspace.shared().icon(forFile: path)
    }
    
    // MARK: Starring
    
    var liked: Bool {
        set { }
        
        get { return false }
    }
    
    // MARK: Callback executors
    
    // The time (in millis) after which
    // the instructions will run
    var delayTime: Int { return 5 }
    
    func execPlayPauseHandler() {
        DispatchQueue.main.run(after: delayTime) { self.playPauseHandler() }
    }
    
    func execShuffleRepeatChangedHandler(shuffleChanged: Bool = false, repeatChanged: Bool = false) {
        DispatchQueue.main.run(after: delayTime) { self.shuffleRepeatChangedHandler(shuffleChanged, repeatChanged) }
    }
    
    // MARK: Notification ID
    
    var TrackChangedNotification: NSNotification.Name {
        // Returns the NSNotification.Name for an observer
        return NSNotification.Name(rawValue: Self.rawTrackChangedNotification)
    }
    
}
