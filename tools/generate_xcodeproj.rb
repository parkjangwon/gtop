#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "fileutils"
require "xcodeproj"

ROOT = Pathname.new(__dir__).join("..").expand_path
PROJECT_PATH = ROOT.join("gtop.xcodeproj")

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH.to_s)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2600"
project.root_object.attributes["LastUpgradeCheck"] = "2600"

def apply_common_settings(target, bundle_id:)
  target.build_configurations.each do |config|
    config.build_settings["SWIFT_VERSION"] = "6.0"
    config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
    config.build_settings["CLANG_ENABLE_MODULES"] = "YES"
    config.build_settings["DEFINES_MODULE"] = "YES"
    config.build_settings["CODE_SIGNING_ALLOWED"] = "NO"
    config.build_settings["CODE_SIGNING_REQUIRED"] = "NO"
    config.build_settings["CODE_SIGN_IDENTITY"] = ""
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_id
    config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  end
end

app_target = project.new_target(:application, "gtop", :osx, "14.0")
framework_target = project.new_target(:framework, "gtopCore", :osx, "14.0")
test_target = project.new_target(:unit_test_bundle, "gtopTests", :osx, "14.0")

apply_common_settings(app_target, bundle_id: "org.parkjw.gtop")
apply_common_settings(framework_target, bundle_id: "org.parkjw.gtop.core")
apply_common_settings(test_target, bundle_id: "org.parkjw.gtop.tests")

app_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_NAME"] = "gtop"
  config.build_settings["INFOPLIST_KEY_LSUIElement"] = "YES"
  config.build_settings["SWIFT_EMIT_LOC_STRINGS"] = "NO"
  config.build_settings["ENABLE_PREVIEWS"] = "YES"
end

test_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_NAME"] = "gtopTests"
end

main_group = project.main_group
source_group = main_group.find_subpath("gtop", true)
test_group = main_group.find_subpath("gtopTests", true)

APP_ONLY_PREFIXES = [
  "gtop/App/",
  "gtop/MenuBar/",
  "gtop/HUD/"
].freeze

SHARED_PREFIXES = [
  "gtop/SharedModels/",
  "gtop/Monitoring/"
].freeze

def add_file(project, group, target, relative_path)
  ref = group.new_file(relative_path)
  target.add_file_references([ref])
end

def add_resource(group, target, relative_path)
  ref = group.new_file(relative_path)
  target.resources_build_phase.add_file_reference(ref, true)
end

Dir.chdir(ROOT) do
  Dir.glob("gtop/**/*.swift").sort.each do |relative_path|
    add_to_app = APP_ONLY_PREFIXES.any? { |prefix| relative_path.start_with?(prefix) } ||
      false
    add_to_framework = SHARED_PREFIXES.any? { |prefix| relative_path.start_with?(prefix) }

    add_file(project, source_group, app_target, relative_path) if add_to_app
    add_file(project, source_group, framework_target, relative_path) if add_to_framework
  end
  Dir.glob("gtopTests/**/*.swift").sort.each do |relative_path|
    ref = test_group.new_file(relative_path)
    test_target.add_file_references([ref])
  end

  Dir.glob("gtop/**/*.xcassets").sort.each do |relative_path|
    add_resource(source_group, app_target, relative_path)
  end
end

test_target.add_dependency(app_target)
app_target.add_dependency(framework_target)
test_target.add_dependency(framework_target)

[app_target, test_target].each do |target|
  target.frameworks_build_phase.add_file_reference(framework_target.product_reference, true)
end

embed_phase = app_target.new_copy_files_build_phase("Embed Frameworks")
embed_phase.dst_subfolder_spec = "10"
embed_phase.add_file_reference(framework_target.product_reference, true)

app_scheme = Xcodeproj::XCScheme.new
app_scheme.add_build_target(app_target)
app_scheme.add_build_target(framework_target)
app_scheme.add_test_target(test_target)
app_scheme.set_launch_target(app_target)
app_scheme.save_as(PROJECT_PATH, "gtop", true)

project.save
