#!/usr/bin/env python3
"""Gera GymRank.xcodeproj/project.pbxproj a partir da lista de ficheiros no disco.

Alvos: GymRank (app, iOS 17), GymRankTests (unit), GymRankUITests (UI).
Correr:  python Tools/gen_pbxproj.py
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_DIR = 'GymRank'
PROJ = 'GymRank.xcodeproj'

SOURCES = [
    'GymRankApp.swift',
    'Engine/RankEngine.swift',
    'Engine/RankComputation.swift',
    'Engine/StandardsData.swift',
    'Models/Models.swift',
    'Networking/WgerClient.swift',
    'Views/Theme.swift',
    'Views/RootView.swift',
    'Views/OnboardingView.swift',
    'Views/DashboardView.swift',
    'Views/BodyPartView.swift',
    'Views/ExerciseDetailView.swift',
    'Views/LogWorkoutView.swift',
    'Views/HistoryView.swift',
    'Views/ProgressView.swift',
    'Views/RanksView.swift',
    'Views/ProfileView.swift',
]
RESOURCES = ['Assets.xcassets']
UNIT_TESTS = ['RankEngineTests.swift']
UI_TESTS = ['GymRankUITests.swift']

for rel in SOURCES + RESOURCES:
    p = os.path.join(ROOT, APP_DIR, rel)
    if not os.path.exists(p):
        raise SystemExit(f'falta o ficheiro: {p}')
for rel in UNIT_TESTS:
    if not os.path.exists(os.path.join(ROOT, 'GymRankTests', rel)):
        raise SystemExit(f'falta o ficheiro: GymRankTests/{rel}')
for rel in UI_TESTS:
    if not os.path.exists(os.path.join(ROOT, 'GymRankUITests', rel)):
        raise SystemExit(f'falta o ficheiro: GymRankUITests/{rel}')

_counter = [0]
def nid():
    _counter[0] += 1
    return f'BB000000000000000000{_counter[0]:04X}'
nid.n = 0

ids = {}
def new(key):
    ids[key] = nid()
    return ids[key]

# ids fixos e legiveis
PROJECT = 'BB0000000000000000000001'
MAIN_GROUP = 'BB0000000000000000000002'
PRODUCTS_GROUP = 'BB0000000000000000000003'
APP_GROUP = 'BB0000000000000000000004'
APP_TARGET = 'BB0000000000000000000005'
APP_PRODUCT = 'BB0000000000000000000006'
PROJ_CONFIG_LIST = 'BB0000000000000000000007'
PROJ_DEBUG = 'BB0000000000000000000008'
PROJ_RELEASE = 'BB0000000000000000000009'
APP_CONFIG_LIST = 'BB000000000000000000000A'
APP_DEBUG = 'BB000000000000000000000B'
APP_RELEASE = 'BB000000000000000000000C'
APP_SOURCES = 'BB000000000000000000000D'
APP_FRAMEWORKS = 'BB000000000000000000000E'
APP_RESOURCES = 'BB000000000000000000000F'
TESTS_GROUP = 'BB0000000000000000000010'
TESTS_TARGET = 'BB0000000000000000000011'
TESTS_PRODUCT = 'BB0000000000000000000012'
TESTS_CONFIG_LIST = 'BB0000000000000000000013'
TESTS_DEBUG = 'BB0000000000000000000014'
TESTS_RELEASE = 'BB0000000000000000000015'
TESTS_SOURCES = 'BB0000000000000000000016'
TESTS_FRAMEWORKS = 'BB0000000000000000000017'
TESTS_RESOURCES = 'BB0000000000000000000018'
TESTS_DEP = 'BB0000000000000000000019'
TESTS_PROXY = 'BB000000000000000000001A'
UITESTS_GROUP = 'BB000000000000000000001B'
UITESTS_TARGET = 'BB000000000000000000001C'
UITESTS_PRODUCT = 'BB000000000000000000001D'
UITESTS_CONFIG_LIST = 'BB000000000000000000001E'
UITESTS_DEBUG = 'BB000000000000000000001F'
UITESTS_RELEASE = 'BB0000000000000000000020'
UITESTS_SOURCES = 'BB0000000000000000000021'
UITESTS_FRAMEWORKS = 'BB0000000000000000000022'
UITESTS_RESOURCES = 'BB0000000000000000000023'
UITESTS_DEP = 'BB0000000000000000000024'
UITESTS_PROXY = 'BB0000000000000000000025'
_counter[0] = 0x25

# ficheiros da app: um grupo por pasta
groups = {'': [], 'Engine': [], 'Models': [], 'Networking': [], 'Views': []}
build_files = []
file_refs = []

for rel in SOURCES:
    folder = os.path.dirname(rel)
    name = os.path.basename(rel)
    ref = new('ref:' + rel)
    bf = new('bf:' + rel)
    file_refs.append((ref, name, rel))
    build_files.append((bf, ref, name))
    groups[folder].append((ref, name))

asset_ref = new('ref:assets')
asset_bf = new('bf:assets')
file_refs.append((asset_ref, 'Assets.xcassets', 'Assets.xcassets'))

unit_ref = new('ref:unit')
unit_bf = new('bf:unit')
file_refs.append((unit_ref, 'RankEngineTests.swift', 'RankEngineTests.swift'))
build_files.append((unit_bf, unit_ref, 'RankEngineTests.swift'))

ui_ref = new('ref:ui')
ui_bf = new('bf:ui')
file_refs.append((ui_ref, 'GymRankUITests.swift', 'GymRankUITests.swift'))
build_files.append((ui_bf, ui_ref, 'GymRankUITests.swift'))

app_product_ref = APP_PRODUCT
unit_product_ref = new('ref:unitproduct')
ui_product_ref = new('ref:uiproduct')

# nomes de grupos por pasta
group_dirs = {k: new('group:' + (k or 'root')) for k in groups}

L = []
w = L.append

w('// !$*UTF8*$!')
w('{')
w('\tarchiveVersion = 1;')
w('\tclasses = {')
w('\t};')
w('\tobjectVersion = 56;')
w('\tobjects = {')
w('')
w('/* Begin PBXBuildFile section */')
for bf, ref, name in build_files:
    w(f'\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};')
w(f'\t\t{asset_bf} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {asset_ref} /* Assets.xcassets */; }};')
w('/* End PBXBuildFile section */')
w('')
w('/* Begin PBXFileReference section */')
for ref, name, rel in file_refs:
    if name.endswith('.swift'):
        w(f'\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};')
    else:
        w(f'\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {name}; sourceTree = "<group>"; }};')
w(f'\t\t{app_product_ref} /* GymRank.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = GymRank.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
w(f'\t\t{unit_product_ref} /* GymRankTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = GymRankTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
w(f'\t\t{ui_product_ref} /* GymRankUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = GymRankUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
w('/* End PBXFileReference section */')
w('')
w('/* Begin PBXFrameworksBuildPhase section */')
for phase, label in ((APP_FRAMEWORKS, 'GymRank'), (TESTS_FRAMEWORKS, 'GymRankTests'), (UITESTS_FRAMEWORKS, 'GymRankUITests')):
    w(f'\t\t{phase} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};')
w('/* End PBXFrameworksBuildPhase section */')
w('')
w('/* Begin PBXGroup section */')
w(f'\t\t{MAIN_GROUP} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{APP_GROUP} /* GymRank */,\n\t\t\t\t{TESTS_GROUP} /* GymRankTests */,\n\t\t\t\t{UITESTS_GROUP} /* GymRankUITests */,\n\t\t\t\t{PRODUCTS_GROUP} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = "<group>";\n\t\t}};')
w(f'\t\t{PRODUCTS_GROUP} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_product_ref} /* GymRank.app */,\n\t\t\t\t{unit_product_ref} /* GymRankTests.xctest */,\n\t\t\t\t{ui_product_ref} /* GymRankUITests.xctest */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = "<group>";\n\t\t}};')

# grupo da app: ficheiros da raiz + subgrupos (os ficheiros vivem SO nos subgrupos)
children = []
for ref, name in groups['']:
    children.append(f'\t\t\t\t{ref} /* {name} */,')
for folder in ['Engine', 'Models', 'Networking', 'Views']:
    children.append(f'\t\t\t\t{group_dirs[folder]} /* {folder} */,')
children.append(f'\t\t\t\t{asset_ref} /* Assets.xcassets */,')
w(f'\t\t{APP_GROUP} /* GymRank */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n' + '\n'.join(children) + '\n\t\t\t);\n\t\t\tpath = GymRank;\n\t\t\tsourceTree = "<group>";\n\t\t};')
for folder in ['Engine', 'Models', 'Networking', 'Views']:
    kids = '\n'.join(f'\t\t\t\t{ref} /* {name} */,' for ref, name in groups[folder])
    w(f'\t\t{group_dirs[folder]} /* {folder} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{kids}\n\t\t\t);\n\t\t\tpath = {folder};\n\t\t\tsourceTree = "<group>";\n\t\t}};')
w(f'\t\t{TESTS_GROUP} /* GymRankTests */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{unit_ref} /* RankEngineTests.swift */,\n\t\t\t);\n\t\t\tpath = GymRankTests;\n\t\t\tsourceTree = "<group>";\n\t\t}};')
w(f'\t\t{UITESTS_GROUP} /* GymRankUITests */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{ui_ref} /* GymRankUITests.swift */,\n\t\t\t);\n\t\t\tpath = GymRankUITests;\n\t\t\tsourceTree = "<group>";\n\t\t}};')
w('/* End PBXGroup section */')
w('')
w('/* Begin PBXNativeTarget section */')
w(f'''\t\t{APP_TARGET} /* GymRank */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {APP_CONFIG_LIST} /* Build configuration list for PBXNativeTarget "GymRank" */;
\t\t\tbuildPhases = (
\t\t\t\t{APP_SOURCES} /* Sources */,
\t\t\t\t{APP_FRAMEWORKS} /* Frameworks */,
\t\t\t\t{APP_RESOURCES} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = GymRank;
\t\t\tproductName = GymRank;
\t\t\tproductReference = {app_product_ref} /* GymRank.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};''')
w(f'''\t\t{TESTS_TARGET} /* GymRankTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {TESTS_CONFIG_LIST} /* Build configuration list for PBXNativeTarget "GymRankTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{TESTS_SOURCES} /* Sources */,
\t\t\t\t{TESTS_FRAMEWORKS} /* Frameworks */,
\t\t\t\t{TESTS_RESOURCES} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{TESTS_DEP} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = GymRankTests;
\t\t\tproductName = GymRankTests;
\t\t\tproductReference = {unit_product_ref} /* GymRankTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};''')
w(f'''\t\t{UITESTS_TARGET} /* GymRankUITests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {UITESTS_CONFIG_LIST} /* Build configuration list for PBXNativeTarget "GymRankUITests" */;
\t\t\tbuildPhases = (
\t\t\t\t{UITESTS_SOURCES} /* Sources */,
\t\t\t\t{UITESTS_FRAMEWORKS} /* Frameworks */,
\t\t\t\t{UITESTS_RESOURCES} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{UITESTS_DEP} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = GymRankUITests;
\t\t\tproductName = GymRankUITests;
\t\t\tproductReference = {ui_product_ref} /* GymRankUITests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t}};''')
w('/* End PBXNativeTarget section */')
w('')
w('/* Begin PBXProject section */')
w(f'''\t\t{PROJECT} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{TESTS_TARGET} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tTestTargetID = {APP_TARGET};
\t\t\t\t\t}};
\t\t\t\t\t{UITESTS_TARGET} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tTestTargetID = {APP_TARGET};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {PROJ_CONFIG_LIST} /* Build configuration list for PBXProject "GymRank" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = pt;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\tpt,
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {MAIN_GROUP};
\t\t\tproductRefGroup = {PRODUCTS_GROUP} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{APP_TARGET} /* GymRank */,
\t\t\t\t{TESTS_TARGET} /* GymRankTests */,
\t\t\t\t{UITESTS_TARGET} /* GymRankUITests */,
\t\t\t);
\t\t}};''')
w('/* End PBXProject section */')
w('')
w('/* Begin PBXResourcesBuildPhase section */')
w(f'\t\t{APP_RESOURCES} /* Resources */ = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{asset_bf} /* Assets.xcassets in Resources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};')
for phase in (TESTS_RESOURCES, UITESTS_RESOURCES):
    w(f'\t\t{phase} /* Resources */ = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};')
w('/* End PBXResourcesBuildPhase section */')
w('')
w('/* Begin PBXSourcesBuildPhase section */')
app_bfs = '\n'.join(f'\t\t\t\t{bf} /* {name} in Sources */,' for bf, ref, name in build_files if name not in ('RankEngineTests.swift', 'GymRankUITests.swift'))
w(f'\t\t{APP_SOURCES} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{app_bfs}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};')
w(f'\t\t{TESTS_SOURCES} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{unit_bf} /* RankEngineTests.swift in Sources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};')
w(f'\t\t{UITESTS_SOURCES} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{ui_bf} /* GymRankUITests.swift in Sources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};')
w('/* End PBXSourcesBuildPhase section */')
w('')
w('/* Begin PBXTargetDependency section */')
for dep, proxy in ((TESTS_DEP, TESTS_PROXY), (UITESTS_DEP, UITESTS_PROXY)):
    w(f'\t\t{dep} /* PBXTargetDependency */ = {{\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = {APP_TARGET} /* GymRank */;\n\t\t\ttargetProxy = {proxy} /* PBXContainerItemProxy */;\n\t\t}};')
w('/* End PBXTargetDependency section */')
w('')
w('/* Begin PBXContainerItemProxy section */')
for proxy in (TESTS_PROXY, UITESTS_PROXY):
    w(f'\t\t{proxy} /* PBXContainerItemProxy */ = {{\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = {PROJECT} /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = {APP_TARGET};\n\t\t\tremoteInfo = GymRank;\n\t\t}};')
w('/* End PBXContainerItemProxy section */')
w('')
w('/* Begin XCBuildConfiguration section */')

def proj_config(cid, name, extra):
    w(f'''\t\t{cid} /* {name} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = {"INCLUDE_SOURCE" if name == "Debug" else "NO"};
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
{extra}\t\t\t}};
\t\t\tname = {name};
\t\t}};''')

common_dbg = '\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;\n\t\t\t\tENABLE_TESTABILITY = YES;\n\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;\n\t\t\t\tONLY_ACTIVE_ARCH = YES;\n\t\t\t\tSWIFT_COMPILATION_MODE = singlefile;\n'
common_rel = '\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";\n\t\t\t\tENABLE_NS_ASSERTIONS = NO;\n\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;\n\t\t\t\tVALIDATE_PRODUCT = YES;\n'
proj_config(PROJ_DEBUG, 'Debug', common_dbg)
proj_config(PROJ_RELEASE, 'Release', common_rel)

app_settings = '''\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = GymRank;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.GymRank;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
'''
unit_settings = '''\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.GymRankTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/GymRank.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/GymRank";
'''
ui_settings = '''\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.GymRankUITests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_TARGET_NAME = GymRank;
'''
for cid, name, settings in ((APP_DEBUG, 'Debug', app_settings), (APP_RELEASE, 'Release', app_settings),
                            (TESTS_DEBUG, 'Debug', unit_settings), (TESTS_RELEASE, 'Release', unit_settings),
                            (UITESTS_DEBUG, 'Debug', ui_settings), (UITESTS_RELEASE, 'Release', ui_settings)):
    w(f'\t\t{cid} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{settings}\t\t\t}};\n\t\t\tname = {name};\n\t\t}};')
w('/* End XCBuildConfiguration section */')
w('')
w('/* Begin XCConfigurationList section */')
for cid, label, dbg, rel in ((PROJ_CONFIG_LIST, f'PBXProject "GymRank"', PROJ_DEBUG, PROJ_RELEASE),
                             (APP_CONFIG_LIST, 'PBXNativeTarget "GymRank"', APP_DEBUG, APP_RELEASE),
                             (TESTS_CONFIG_LIST, 'PBXNativeTarget "GymRankTests"', TESTS_DEBUG, TESTS_RELEASE),
                             (UITESTS_CONFIG_LIST, 'PBXNativeTarget "GymRankUITests"', UITESTS_DEBUG, UITESTS_RELEASE)):
    w(f'\t\t{cid} /* Build configuration list for {label} */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{dbg} /* Debug */,\n\t\t\t\t{rel} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};')
w('/* End XCConfigurationList section */')
w('\t};')
w(f'\trootObject = {PROJECT} /* Project object */;')
w('}')

out_dir = os.path.join(ROOT, PROJ)
os.makedirs(out_dir, exist_ok=True)
path = os.path.join(out_dir, 'project.pbxproj')
open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
print(f'escrito {path}')
print(f'  ficheiros Swift na app: {len([s for s in SOURCES])}')
print(f'  alvos: GymRank, GymRankTests, GymRankUITests')
