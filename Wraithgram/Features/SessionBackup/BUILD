load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# Feature module WGSessionBackup, «Бэкап аккаунтов» (Swiftgram Pro's "Session backup", Keychain format
# compatible with the old client). May depend on everything below TelegramUI; never on TelegramUI or
# another WG<Feature> module (FOUNDATION_SPEC §1.1).
swift_library(
    name = "WGSessionBackup",
    module_name = "WGSessionBackup",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Wraithgram/WGCore:WGCore",
        "//Wraithgram/WGHooks:WGHooks",
        "//Wraithgram/WGSettingsUI:WGSettingsUI",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AlertUI:AlertUI",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/UndoUI:UndoUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
