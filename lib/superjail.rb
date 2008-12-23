module Superjail
  
  Version = "0.1.0"
  
  class Jailkit
    class <<self
      def install
        url = "http://olivier.sessink.nl/jailkit/jailkit-2.5.tar.gz"
        RUBY_PLATFORM.downcase.include?("darwin") ?
          run("curl #{url} -O") :
          run("wget --quiet #{url}")
        name = File.basename(url).gsub('.tar.gz', '')
        run "tar xzf #{name}*"
        run "cd #{name} && make configure && ./configure --prefix=/usr/local && make && sudo make install"
        run "rm -Rf #{name}"
        run "rm -Rf #{name}*"
      end

      def run(cmd)
        puts cmd
        puts `#{cmd}`
      end
    end
  end
  
  class Jail
    class <<self
      def create(jail, options={})
        options = {
          :config   => '/usr/local/etc/jailkit/jk_init.ini',
          :verbose  => true,
          :force    => true,
          :hardlink => false,
          :sections => [ :jk_lsh ],
          :shell    => nil
        }.merge(options)
        if options[:shell]
          `touch /tmp/jk_lsh.ini`
          options[:sections].collect! do |value|
            value.to_s == 'jk_lsh' ? :custom_jk_lsh : value
          end
        end
        if options[:config].respond_to?(:keys)
          config = options[:config]
          options[:config] = '/tmp/jk_init.ini'
          # Add this config to /tmp/jk_init.ini (only support what you need for now)
          # {
          #   :ruby => {
          #   :paths => /usr/local/lib/ruby
          #   :executables => /usr/local/bin/ruby, /usr/local/bin/gem
          # }
          # If options[:sections].index(:custom_jk_lsh)
          #   [custom_jk_lsh]
          #   comment = custom Jailkit limited shell
          #   executables = /usr/sbin/jk_lsh
          #   regularfiles = /tmp/jk_lsh.ini
          #   users = root
          #   groups = root
          #   need_logsocket = 1
          #   includesections = uidbasics
          #
          #   Using config
          #     :shell => {
          #       :executables => /usr/local/bin/ruby
          #       :paths => /usr/local/bin, /usr/local/lib/ruby
          #       :allow_word_expansion => 1
          #     }
        end
      end
    end
    
    class User
      class <<self
        # Create user and jail
        def create(user, options={})
        end
        
        # Execute command in jail as user
        # Create user and jail if either do not exist
        def execute_as(user, options={})
        end

        def jail(user, options={})
          options = {
            :jail      => '/jail',
            :verbose   => true,
            :verbose   => true,
            :shell     => '/usr/sbin/jk_lsh',
            :move_home => true
          }.merge(options)
          # Generate command and execute
          #   Always run with --noninteractive
        end
      end
    end
  end
end