Dir["#{File.dirname(__FILE__)}/superjail/*.rb"].each { |f| require f }

module Superjail
  Version = "0.1.0"
end