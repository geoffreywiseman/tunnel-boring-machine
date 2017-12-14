def stub_messages
  @messages = []
  allow($stdout).to receive( :write ) { |message| @messages << message  }
end

def surpress_messages
  allow($stdout).to receive( :write )
end

RSpec::Matchers.define :include_match do |expected|
  match do |actual|
     !actual.grep( expected ).empty?
  end
end
