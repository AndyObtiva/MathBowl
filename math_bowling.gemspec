# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: math_bowling 2.2.0 ruby vendor

Gem::Specification.new do |s|
  s.name = "math_bowling".freeze
  s.version = "2.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["vendor".freeze]
  s.authors = ["Andy Maleh".freeze]
  s.date = "2020-08-05"
  s.description = "Math Game with Bowling Rules".freeze
  s.email = "andy.am@gmail.com".freeze
  s.executables = ["math_bowling".freeze]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".rspec",
    ".ruby-gemset",
    ".ruby-version",
    "Gemfile",
    "LICENSE.txt",
    "Math-Bowling-Screenshot.png",
    "MathBowling-2.0.0-Demo-2Players.mp4",
    "MathBowling-2.0.0-Demo-4Players.gif",
    "MathBowling-2.0.0-Demo-4Players.mp4",
    "PLAN.md",
    "README.md",
    "Rakefile",
    "VERSION",
    "app/math_bowling.rb",
    "app/models/math_bowling/frame.rb",
    "app/models/math_bowling/game.rb",
    "app/models/math_bowling/game_options.rb",
    "app/models/math_bowling/player.rb",
    "app/models/math_bowling/score_sheet.rb",
    "app/models/math_bowling/video_repository.rb",
    "app/views/math_bowling/app_menu_bar.rb",
    "app/views/math_bowling/app_view.rb",
    "app/views/math_bowling/difficulty_view.rb",
    "app/views/math_bowling/excludable_composite.rb",
    "app/views/math_bowling/frame_view.rb",
    "app/views/math_bowling/game_menu_bar.rb",
    "app/views/math_bowling/game_rules_dialog.rb",
    "app/views/math_bowling/game_view.rb",
    "app/views/math_bowling/math_operation_view.rb",
    "app/views/math_bowling/player_count_view.rb",
    "app/views/math_bowling/score_board_view.rb",
    "app/views/math_bowling/splash.rb",
    "bin/math_bowling",
    "config/warble.rb",
    "docs/game_rules.html",
    "fonts/AbadiMTCondensedExtraBold.ttf",
    "images/math-bowling-background.jpg",
    "images/math-bowling-logo.png",
    "images/math-bowling.gif",
    "package/macosx/Math Bowling 2.icns",
    "package/windows/Math Bowling 2.ico",
    "spec/app/models/math_bowling/game_spec.rb",
    "spec/spec_helper.rb",
    "videos/bowling-close-full1.mp4",
    "videos/bowling-close-full2.mp4",
    "videos/bowling-close-full3.mp4",
    "videos/bowling-close-full4.mp4",
    "videos/bowling-close-full5.mp4",
    "videos/bowling-close-partial1.mp4",
    "videos/bowling-close-partial2.mp4",
    "videos/bowling-close-partial3.mp4",
    "videos/bowling-correct-full1.mp4",
    "videos/bowling-correct-full2.mp4",
    "videos/bowling-correct-full3.mp4",
    "videos/bowling-correct-full4.mp4",
    "videos/bowling-correct-full5.mp4",
    "videos/bowling-correct-partial1.mp4",
    "videos/bowling-correct-partial2.mp4",
    "videos/bowling-correct-partial3.mp4",
    "videos/bowling-correct-partial4.mp4",
    "videos/bowling-correct-partial5.mp4",
    "videos/bowling-wrong-full1.mp4",
    "videos/bowling-wrong-partial1.mp4",
    "videos/bowling-wrong-partial2.mp4",
    "videos/bowling-wrong-partial3.mp4"
  ]
  s.homepage = "http://github.com/AndyObtiva/math_bowling".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.6".freeze
  s.summary = "Math Game with Bowling Rules".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<glimmer-dsl-swt>.freeze, ["= 0.5.5"])
      s.add_runtime_dependency(%q<glimmer-cw-video>.freeze, ["= 0.1.3"])
      s.add_runtime_dependency(%q<to_collection>.freeze, ["= 2.0.0"])
      s.add_runtime_dependency(%q<array_include_methods>.freeze, ["= 1.0.1"])
      s.add_development_dependency(%q<glimmer-cs-gladiator>.freeze, [">= 0"])
    else
      s.add_dependency(%q<glimmer-dsl-swt>.freeze, ["= 0.5.5"])
      s.add_dependency(%q<glimmer-cw-video>.freeze, ["= 0.1.3"])
      s.add_dependency(%q<to_collection>.freeze, ["= 2.0.0"])
      s.add_dependency(%q<array_include_methods>.freeze, ["= 1.0.1"])
      s.add_dependency(%q<glimmer-cs-gladiator>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<glimmer-dsl-swt>.freeze, ["= 0.5.5"])
    s.add_dependency(%q<glimmer-cw-video>.freeze, ["= 0.1.3"])
    s.add_dependency(%q<to_collection>.freeze, ["= 2.0.0"])
    s.add_dependency(%q<array_include_methods>.freeze, ["= 1.0.1"])
    s.add_dependency(%q<glimmer-cs-gladiator>.freeze, [">= 0"])
  end
end

