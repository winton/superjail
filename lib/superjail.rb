require 'erb'

module Superjail
  Version = "0.1.0"
  
  module Helpers
    Debug = false
    
    # Execute a command and display the output
    def run(cmd)
      puts "\nRunning command:\n#{cmd}\nOutput:\n"
      puts `#{cmd}` unless Debug
    end
    
    # Write text to a file
    def write(path, text, mode='a')
      puts "\nWriting to #{path}:\n#{text}"
      File.open(path, mode) { |f| f.write(text) } unless Debug
    end
  end
  
  class Jailkit
    class <<self
      include Helpers
      
      def install
        # Download jailkit
        url = "http://olivier.sessink.nl/jailkit/jailkit-2.5.tar.gz"
        RUBY_PLATFORM.downcase.include?("darwin") ?
          run("curl #{url} -O") :
          run("wget --quiet #{url}")
        # Install jailkit
        name = File.basename(url).gsub('.tar.gz', '')
        run "tar xzf #{name}*"
        run "cd #{name} && make configure && ./configure && make && sudo make install"
        run "rm -Rf #{name}"
        run "rm -Rf #{name}*"
      end
    end
  end
  
  class Jail
    class <<self
      include Helpers
      
      # Executes /usr/bin/jk_init
      def create(jail, options={})
        # Default options
        options = {
          :config      => '/etc/jailkit/jk_init.ini',
          :force       => true,
          :hardlink    => false,
          :sections    => [],
          :shell       => nil,
          :temp_config => '/tmp/jk_init.ini',
          :verbose     => true
        }.merge(options)
        # Templates
        templates = "#{File.dirname(__FILE__)}/../templates/"
        custom_section = ERB.new(File.read("#{templates}custom_section.erb"))
        jk_lsh_config  = ERB.new(File.read("#{templates}jk_lsh_config.erb"))
        # Copy config to temp_config
        FileUtils.cp(options[:config], options[:temp_config]) unless Debug
        # If custom shell
        if options[:shell]
          # Add jk_lsh to sections list
          options[:sections] << :jk_lsh
        end
        # Search for custom sections (hashes)
        options[:sections].each_index do |index|
          config = options[:sections][index]
          # If options[:sections] contains a hash, it defines a custom section
          if config.respond_to?(:keys)
            # Append custom_section to temp_config
            write options[:temp_config], custom_section.result(binding)
            # Replace hash with name so it is included in the final jk_init call
            options[:sections][index] = config[:name]
          end
        end
        # Build call parameters
        params = []
        params.push('-v') if options[:verbose]
        params.push('-f') if options[:force]
        params.push('-k') if options[:hardlink]
        params.push('-c ' +  options[:temp_config])
        # Throw exception if no jail or sections?
        params.push('-j ' + jail)
        params.push(options[:sections].join(' '))
        # Execute /usr/sbin/jk_init call
        run "jk_init #{params.join(' ')}"
        # If custom shell, create jk_lsh_config inside the jail
        if options[:shell]
          config = options[:shell]
          path = jail + '/etc/jailkit/jk_lsh.ini'
          run "mkdir -p #{File.dirname path}"
          run "touch #{path}"
          write path, jk_lsh_config.result(binding), 'w'
        end
      end
    end
    
    class User
      class <<self
        include Helpers
        
        # Create and jail user
        def create(jail, group, user, password)
          run "groupadd -f #{group}"
          run "useradd -g #{group} -p #{password} #{user}"
          run "jk_jailuser -n -v -m -j #{jail} #{user}"
          # Add user to limits.conf
        end
        
        # Execute command in jail as user
        # Create user if does not exist
        def execute_as_jailed_user(cmd, jail, group, user, password)
          if `grep "^#{user}:" /etc/passwd`.empty?
            create jail, group, user, password
          end
          run cmd
        end
      end
    end
  end
end