module Superjail
  module Install
    def jailkit
      install "http://olivier.sessink.nl/jailkit/jailkit-2.5.tar.gz"
    end
  
    def install(url)
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