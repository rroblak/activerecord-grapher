require 'logger'

# Mock Rails.application.eager_load! and define some
# Rails models for use in specs.
class Rails
  @@logger = Logger.new(STDOUT)

  def self.application
    self
  end

  def self.eager_load!
		true
	end

  def self.logger
    @@logger
  end
end

def remove_constants(*constants)
  constants.each {|c| Object.send(:remove_const, c)}
  constants
end

