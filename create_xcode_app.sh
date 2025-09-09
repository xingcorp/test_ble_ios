#!/bin/bash

echo "🚀 Creating iOS App Project for Beacon Attendance..."

# Create iOS App directory structure
mkdir -p BeaconAttendanceApp
cd BeaconAttendanceApp

# Create the Xcode project using xcodebuild
cat > create_project.swift << 'EOF'
import Foundation

let projectName = "BeaconAttendance"
let bundleId = "com.oxii.beacon-attendance"
let path = FileManager.default.currentDirectoryPath

// Create xcodeproj using xcodeproj command
let createProject = """
xcodegen generate --spec project.yml
"""

// First create project.yml for XcodeGen
let projectYml = """
name: BeaconAttendance
options:
  bundleIdPrefix: com.oxii
  deploymentTarget:
    iOS: 14.0
  createIntermediateGroups: true
  
settings:
  base:
    PRODUCT_BUNDLE_IDENTIFIER: \(bundleId)
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    INFOPLIST_FILE: BeaconAttendance/Info.plist
    SWIFT_VERSION: 5.7
    IPHONEOS_DEPLOYMENT_TARGET: 14.0
    TARGETED_DEVICE_FAMILY: "1,2"
    
targets:
  BeaconAttendance:
    type: application
    platform: iOS
    deploymentTarget: 14.0
    sources:
      - BeaconAttendance
    dependencies:
      - package: BeaconAttendanceCore
        product: BeaconAttendanceCore
      - package: BeaconAttendanceFeatures
        product: BeaconAttendanceFeatures
    settings:
      base:
        INFOPLIST_FILE: BeaconAttendance/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: \(bundleId)
        
packages:
  BeaconAttendanceCore:
    path: ../
  BeaconAttendanceFeatures:
    path: ../
"""

try! projectYml.write(toFile: "project.yml", atomically: true, encoding: .utf8)
print("✅ Created project.yml")
EOF

swift create_project.swift

# Create actual iOS app with storyboard
echo "📱 Creating iOS App with Xcode..."

# Use Xcode command line to create a new iOS app project
xcodebuild -create-project \
    -name BeaconAttendance \
    -type "iOS App" \
    -language Swift \
    -bundleID "com.oxii.beacon-attendance" 2>/dev/null || {
    
    # Alternative: Create using xcodeproj template
    echo "Creating iOS App structure manually..."
    
    # Create directory structure
    mkdir -p BeaconAttendance
    mkdir -p BeaconAttendance.xcodeproj
    mkdir -p BeaconAttendance/Base.lproj
    mkdir -p BeaconAttendance/Assets.xcassets
    
    # Copy files from Package sources
    cp -r ../Sources/App/* BeaconAttendance/ 2>/dev/null || true
    
    # Create a basic project.pbxproj
    cat > BeaconAttendance.xcodeproj/project.pbxproj << 'PBXPROJ'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		1D1234561234567812345678 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1D1234551234567812345678 /* AppDelegate.swift */; };
		1D1234581234567812345678 /* SceneDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1D1234571234567812345678 /* SceneDelegate.swift */; };
		1D12345A1234567812345678 /* ViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1D1234591234567812345678 /* ViewController.swift */; };
		1D12345D1234567812345678 /* Main.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 1D12345B1234567812345678 /* Main.storyboard */; };
		1D12345F1234567912345678 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 1D12345E1234567912345678 /* Assets.xcassets */; };
		1D1234621234567912345678 /* LaunchScreen.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 1D1234601234567912345678 /* LaunchScreen.storyboard */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		1D1234521234567812345678 /* BeaconAttendance.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BeaconAttendance.app; sourceTree = BUILT_PRODUCTS_DIR; };
		1D1234551234567812345678 /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; };
		1D1234571234567812345678 /* SceneDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SceneDelegate.swift; sourceTree = "<group>"; };
		1D1234591234567812345678 /* ViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ViewController.swift; sourceTree = "<group>"; };
		1D12345C1234567812345678 /* Base */ = {isa = PBXFileReference; lastKnownFileType = file.storyboard; name = Base; path = Base.lproj/Main.storyboard; sourceTree = "<group>"; };
		1D12345E1234567912345678 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		1D1234611234567912345678 /* Base */ = {isa = PBXFileReference; lastKnownFileType = file.storyboard; name = Base; path = Base.lproj/LaunchScreen.storyboard; sourceTree = "<group>"; };
		1D1234631234567912345678 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		1D12344F1234567812345678 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		1D1234491234567812345678 = {
			isa = PBXGroup;
			children = (
				1D1234541234567812345678 /* BeaconAttendance */,
				1D1234531234567812345678 /* Products */,
			);
			sourceTree = "<group>";
		};
		1D1234531234567812345678 /* Products */ = {
			isa = PBXGroup;
			children = (
				1D1234521234567812345678 /* BeaconAttendance.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		1D1234541234567812345678 /* BeaconAttendance */ = {
			isa = PBXGroup;
			children = (
				1D1234551234567812345678 /* AppDelegate.swift */,
				1D1234571234567812345678 /* SceneDelegate.swift */,
				1D1234591234567812345678 /* ViewController.swift */,
				1D12345B1234567812345678 /* Main.storyboard */,
				1D12345E1234567912345678 /* Assets.xcassets */,
				1D1234601234567912345678 /* LaunchScreen.storyboard */,
				1D1234631234567912345678 /* Info.plist */,
			);
			path = BeaconAttendance;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		1D1234511234567812345678 /* BeaconAttendance */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 1D1234661234567912345678 /* Build configuration list for PBXNativeTarget "BeaconAttendance" */;
			buildPhases = (
				1D12344E1234567812345678 /* Sources */,
				1D12344F1234567812345678 /* Frameworks */,
				1D1234501234567812345678 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = BeaconAttendance;
			productName = BeaconAttendance;
			productReference = 1D1234521234567812345678 /* BeaconAttendance.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		1D12344A1234567812345678 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1430;
				LastUpgradeCheck = 1430;
				TargetAttributes = {
					1D1234511234567812345678 = {
						CreatedOnToolsVersion = 14.3.1;
					};
				};
			};
			buildConfigurationList = 1D12344D1234567812345678 /* Build configuration list for PBXProject "BeaconAttendance" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 1D1234491234567812345678;
			productRefGroup = 1D1234531234567812345678 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				1D1234511234567812345678 /* BeaconAttendance */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		1D1234501234567812345678 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				1D1234621234567912345678 /* LaunchScreen.storyboard in Resources */,
				1D12345F1234567912345678 /* Assets.xcassets in Resources */,
				1D12345D1234567812345678 /* Main.storyboard in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		1D12344E1234567812345678 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				1D12345A1234567812345678 /* ViewController.swift in Sources */,
				1D1234561234567812345678 /* AppDelegate.swift in Sources */,
				1D1234581234567812345678 /* SceneDelegate.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXVariantGroup section */
		1D12345B1234567812345678 /* Main.storyboard */ = {
			isa = PBXVariantGroup;
			children = (
				1D12345C1234567812345678 /* Base */,
			);
			name = Main.storyboard;
			sourceTree = "<group>";
		};
		1D1234601234567912345678 /* LaunchScreen.storyboard */ = {
			isa = PBXVariantGroup;
			children = (
				1D1234611234567912345678 /* Base */,
			);
			name = LaunchScreen.storyboard;
			sourceTree = "<group>";
		};
/* End PBXVariantGroup section */

/* Begin XCBuildConfiguration section */
		1D1234641234567912345678 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		1D1234651234567912345678 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		1D1234671234567912345678 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = BeaconAttendance/Info.plist;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UIMainStoryboardFile = Main;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.oxii.beacon-attendance";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		1D1234681234567912345678 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = BeaconAttendance/Info.plist;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UIMainStoryboardFile = Main;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.oxii.beacon-attendance";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		1D12344D1234567812345678 /* Build configuration list for PBXProject "BeaconAttendance" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				1D1234641234567912345678 /* Debug */,
				1D1234651234567912345678 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		1D1234661234567912345678 /* Build configuration list for PBXNativeTarget "BeaconAttendance" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				1D1234671234567912345678 /* Debug */,
				1D1234681234567912345678 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = 1D12344A1234567812345678 /* Project object */;
}
PBXPROJ
}

echo "✅ Created Xcode project structure"
echo ""
echo "📂 Project created at: $(pwd)/BeaconAttendance.xcodeproj"
echo ""
echo "🎯 Next steps:"
echo "1. Open BeaconAttendance.xcodeproj in Xcode"
echo "2. Add your Development Team in Signing & Capabilities"
echo "3. Connect the Swift Package (File > Add Package Dependencies > Add Local > select parent folder)"
echo "4. Build and run on a physical device"

# Make script executable
chmod +x create_xcode_app.sh
