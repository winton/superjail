require 'erb'

module Superjail
  Version = "0.1.0"
  
  module Helpers
    Debug = true
    
    # Assign default options and bind as local vars
    def default_options(default, options, bind)
      options = default.merge(options)
      options.each { |key, value| eval("@#{key} = #{value.inspect}", bind) }
    end
    
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
        # Install mkpasswd
        run "apt-get install whois"
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
      
      # Executes jk_init
      def create(options={})
        # Default options
        default_options({
          :config      => '/etc/jailkit/jk_init.ini',
          :force       => true,
          :hardlink    => false,
          :jail        => '/jail',
          :sections    => [],
          :shell       => nil,
          :temp_config => '/tmp/jk_init.ini',
          :verbose     => true
        }, options, binding)
        # Templates
        templates = "#{File.dirname(__FILE__)}/../templates/"
        custom_section = ERB.new(File.read("#{templates}custom_section.erb"))
        jk_lsh_config  = ERB.new(File.read("#{templates}jk_lsh_config.erb"))
        # Copy config to temp_config
        FileUtils.cp(@config, @temp_config) unless Debug
        # If custom shell
        if @shell
          # Add jk_lsh to sections list
          @sections << :jk_lsh
        end
        # Search for custom sections (hashes)
        @sections.each_index do |index|
          section = @sections[index]
          # If sections contains a hash, it defines a custom section
          if section.respond_to?(:keys)
            # Append custom_section to temp_config
            write @temp_config, custom_section.result(binding)
            # Replace hash with name so it is included in the final jk_init call
            @sections[index] = section[:name]
          end
        end
        # Build call parameters
        params = []
        params.push('-v') if @verbose
        params.push('-f') if @force
        params.push('-k') if @hardlink
        params.push('-c ' + @temp_config)
        params.push('-j ' + @jail)
        params.push(@sections.join(' '))
        # Execute /usr/sbin/jk_init call
        run "jk_init #{params.join(' ')}"
        # If custom shell, create jk_lsh_config inside the jail
        if shell
          path = @jail + '/etc/jailkit/jk_lsh.ini'
          run "mkdir -p #{File.dirname path}"
          run "touch #{path}"
          write path, jk_lsh_config.result(binding), 'w'
        end
      end
      
      # Delete jail
      def destroy(jail)
        run "rm -Rf #{jail}"
      end
    end
    
    class User
      class <<self
        include Helpers
        
        # Create and jail user
        def create(options={})
          # Default options
          default_options({
            :jail     => '/jail',
            :group    => 'jailed',
            :user     => 'jailed',
            :password => 'lockmeup'
          }, options, binding)
          # Create group
          run "groupadd -f #{@group}"
          # Create user
          run "useradd -m -g #{@group} -p `mkpasswd #{@password}` #{@user}"
          # Move user to jail
          run "jk_jailuser -n -v -m -j #{@jail} #{@user}"
          # TODO: Add group to limits.conf (if not already present)
        end
        
        # Delete jailed user
        def destroy(jail, user)
          run "userdel -f -r #{user}"
        end
        
        # Execute command in jail as user
        def execute_as_jailed_user(cmd, jail, group, user, password)
          # Create user if does not exist
          if `grep "^#{user}:" /etc/passwd`.empty?
            create jail, group, user, password
          end
          # TODO: Programatically add 'su without password' privileges for root
          # http://cosminswiki.com/index.php/How_to_let_users_su_without_password
          run "su #{user} -c '#{cmd}'"
        end
      end
    end
  end
end