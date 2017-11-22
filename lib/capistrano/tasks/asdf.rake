namespace :asdf do
  task :validate do
    on release_roles(fetch(:asdf_roles)) do |host|
      asdf_ruby = fetch(:asdf_ruby)
      if asdf_ruby.nil?
        info 'asdf: asdf_ruby is not set; ruby version will be defined by the remote hosts via asdf'
      end

      # Don't check the asdf_ruby_dir if :asdf_ruby is not set (it will always fail)
      unless asdf_ruby.nil? || (test "[ -d #{fetch(:asdf_ruby_dir)} ]")
        warn "asdf: #{asdf_ruby} is not installed or not found in #{fetch(:asdf_ruby_dir)} on #{host}"
        exit 1
      end
    end
  end

  task :map_bins do
    SSHKit.config.default_env.merge!({ asdf_root: fetch(:asdf_path), asdf_version: fetch(:asdf_ruby) })
    asdf_prefix = fetch(:asdf_prefix, proc { "#{fetch(:asdf_path)}/bin/asdf exec" })
    SSHKit.config.command_map[:asdf] = "#{fetch(:asdf_path)}/bin/asdf"

    fetch(:asdf_map_bins).uniq.each do |command|
      SSHKit.config.command_map.prefix[command.to_sym].unshift(asdf_prefix)
    end
  end
end

Capistrano::DSL.stages.each do |stage|
  after stage, 'asdf:validate'
  after stage, 'asdf:map_bins'
end

namespace :load do
  task :defaults do
    set :asdf_path, -> {
      asdf_path = fetch(:asdf_custom_path)
      asdf_path ||= '$HOME/.asdf'
    }

    set :asdf_roles, fetch(:asdf_roles, :all)

    set :asdf_ruby_dir, -> { "#{fetch(:asdf_path)}/installs/ruby/#{fetch(:asdf_ruby)}" }
    set :asdf_map_bins, %w{rake gem bundle ruby rails}
  end
end
