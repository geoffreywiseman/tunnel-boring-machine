require 'tunnel/cli'
require 'tunnel/config'
require 'tunnel/target'
require 'tunnel/meta'

describe Tunnel::CommandLineInterface do

	let( :config ) { double( Tunnel::Config ) }
	subject { Tunnel::CommandLineInterface.new config }

	before do
		Tunnel::Config.stub( :new ) { config }
		config.stub( :valid? ) { config_valid }
		config.stub( :errors ) { config_errors }
		stub_messages
	end

	context "without valid config" do
		let(:config_valid) { false }
		let(:config_errors) { ["Invalid Config"] }
		it "should print config errors" do
			Tunnel::CommandLineInterface.parse_and_run
			@messages.should include_match(/Cannot parse config/)
			@messages.should include_match(/Invalid Config/)
		end
	end

	context "with no parameters" do
		let(:config_valid) { true }

		before do
			ARGV.clear
			config.stub(:each_target).and_yield( 'alpha' ).and_yield( 'beta' )
		end

		it "should print syntax and targets" do
			Tunnel::CommandLineInterface.parse_and_run
			@messages.should include_match( /SYNTAX/ )
			@messages.should include_match( /alpha/ )
			@messages.should include_match( /beta/ )
		end
	end

	context "with multiple parameters" do
		let(:config_valid) { true }

		before do
			ARGV.clear.push( 'alpha', 'beta' )
			config.stub(:each_target).and_yield( 'alpha' ).and_yield( 'beta' )
		end

		it "should print syntax and targets" do
			Tunnel::CommandLineInterface.parse_and_run
			@messages.should include_match( /SYNTAX/ )
			@messages.should include_match( /alpha/ )
			@messages.should include_match( /beta/ )
		end
	end

	context "with a single parameter" do
		let(:config_valid) { true }

		before do
			ARGV.clear.push( 'target-name' )
			config.stub(:get_target).with('target-name') { target }
		end

		context "matching a config target" do
			let(:target) { double Tunnel::Target }
			let(:thost) { 'target-host.example.com' }
			let(:tuser) { 'username' }

			before do
				target.stub(:host) { thost }
				target.stub(:username) { tuser }
			end

			it "should start an SSH connection" do
				Net::SSH.stub(:start).with(thost,tuser)
				Tunnel::CommandLineInterface.parse_and_run
			end
		end

		context "not matching a config target" do
			let(:target) { nil }

			before do
				config.stub(:each_target).and_yield( 'another-target' )
			end

			it "should say 'Cannot find target'" do
				Tunnel::CommandLineInterface.parse_and_run
				@messages.should include_match( /Cannot find target/ )
			end

			it "should print target list" do
				Tunnel::CommandLineInterface.parse_and_run
				@messages.should include_match( /another-target/ )
			end
		end
	end

end