require 'tunnel/config'
require 'rspec'

describe Tunnel::Config do
	CONFIG_FILE = File.expand_path( "~/.tunnels" )

	context "when config doesn't exist" do
		before do
			stub_messages
			File.stub( :file? ).with( CONFIG_FILE ) { false }
		end

		it "should say 'Configure your tunnels'" do
			subject.should_not be_valid
			@messages.should include_match /Configure your tunnels/
		end
	end

	context "when config file exists" do
		it "should load config with YAML"

		context "when config is not a hash" do
			it "should warn that it can't parse config"
		end

		context "when config is a hash (of targets)" do

			context "when target config is not a hash" do
				it "should warn that can't parse the target"
			end

			context "when target config is a hash" do

				context "when target config doesn't have a name" do
					it "should warn that targets must have a name"
				end

				context "when target config has a name" do
					it "should create target with host"
					it "should take username from config if specified"
					it "should take username from environment if not specified"

					context "when target config has no forward" do
						it "should warn targets must have forwards"
					end

					context "when target config has a forward" do
						it "should treat integer as a port"
						it "should treat array as list of ports"
						it "should treat hash as list of servers, with ports for each"
						it "should warn if forward is not whole number"
						it "should warn if port is negative"
						it "should warn if port contains characters"
						it "should warn if array contains invalid ports"
					end

					context "when target config has a an alias" do
						it "should treat string as single alias"
						it "should treat array as list of aliases"
						it "should warn with any other content"
					end

				end

				it "should make a target from the hash"
			end

			it "should make a target from each entry"
		end
	end
end