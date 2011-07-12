#!/usr/bin/env ruby
require 'fileutils'

Dir.glob 'dot/*' do |file|
  original = File.expand_path file
  link = File.join File.expand_path('~'), ".#{File.basename file}"
  if not File.exists? link
    FileUtils.ln_s original, link
  end
end
