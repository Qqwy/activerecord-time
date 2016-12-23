#!/usr/bin/env ruby -w

system('rubocop --auto-correct') || exit(1)

update_gemfiles = ARGV.delete('--update')

require 'yaml'
travis = YAML.load(File.read('.travis.yml'))

travis['rvm'].each do |ruby|
  next if ruby =~ /head/
  puts '#' * 80
  puts "Testing #{ruby}"
  puts
  system "ruby-install --no-reinstall #{ruby}" || exit(1)
  bundler_gem_check_cmd = "chruby-exec #{ruby} -- gem query -i -n bundler >/dev/null"
  system "#{bundler_gem_check_cmd} || chruby-exec #{ruby} -- gem install bundler" || exit(1)
  travis['gemfile'].each do |gemfile|
    if travis['matrix']['exclude'].any? { |f| f['rvm'] == ruby && f['gemfile'] == gemfile }
      puts 'Skipping known failure.'
      next
    end
    puts '$' * 80
    puts "Testing #{gemfile}"
    puts
    ENV['BUNDLE_GEMFILE'] = gemfile
    if update_gemfiles
      system "chruby-exec #{ruby} -- bundle update"
    else
      system "chruby-exec #{ruby} -- bundle check || chruby-exec #{ruby} -- bundle install"
    end || exit(1)
    travis['env'].each do |env|
      env.scan(/\b(?<key>[A-Z_]+)="(?<value>.+?)"/) do |key, value|
        ENV[key] = value
      end
      puts '*' * 80
      puts "Testing #{ruby} #{gemfile} #{env}"
      puts
      system "chruby-exec #{ruby} -- bundle exec rake" || exit(1)
      puts '*' * 80
    end
    puts "Testing #{gemfile} OK"
    puts '$' * 80
  end
  puts "Testing #{ruby} OK"
  puts '#' * 80
end

print "\033[0;32m"
print '                        TESTS PASSED OK!'
puts "\033[0m"
