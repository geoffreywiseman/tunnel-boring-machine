def stub_messages
  @messages = []
  $stdout.stub( :write ) { |message| @messages << message  }
end

def surpress_messages
  $stdout.stub( :write )
end

RSpec::Matchers.define :include_match do |expected|
  match do |actual|
     !actual.grep( expected ).empty?
  end
end
